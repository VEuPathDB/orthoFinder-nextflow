#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { uncompressFastas as uncompressChangedFastas;
          combineProteomes;
          calculateGroupStats as calculatePeripheralStatsForTouched;
          calculateGroupStats as calculateCoreStatsForTouched;
          makeEmptyFile as makeEmptyFileForPeripheralStats;
          makeEmptyFile as makeEmptyFileForCoreStats;
          makeEmptyFile as makeEmptyFileForIntraGroupBlast;
          makeEmptyFile as makeEmptyFileForIntraResidualGroupBlast;
          mergeByGroupId as mergePeripheralStatsByGroupId;
          mergeByGroupId as mergeCoreStatsByGroupId;
          mergeByGroupId as mergeIntraGroupBlastByGroupId;
          mergeByGroupId as mergeResidualStatsByGroupId;
          mergeByGroupId as mergeIntraResidualGroupBlastByGroupId;
        } from './shared.nf'
include { makeResidualAndPeripheralFastas as splitAssignedAndResidual;
          createCompressedResidualFastaDir; makeCoreBestRepresentativesFasta; createIntraGroupBlastFile
        } from './peripheral.nf'
include { residualWorkflow } from './residual.nf'
include { makeResidualBestRepresentativesFasta;
          calculateResidualGroupStats as calculateResidualStatsForTouched;
          createIntraResidualGroupBlastFile as createIntraResidualGroupBlastFileForTouched;
        } from './postResidual.nf'


/**
 * Filter the previous run's core+residual group files down to "stable"
 * membership: drop any member sequence belonging to a changed/removed
 * organism, using the persisted protein-to-organism map (not sequence-ID
 * parsing, since not every proteome source encodes organism in its IDs).
 *
 * @param fullGroupFile: previous run's core+peripheral groups (cached)
 * @param residualGroupFile: previous run's residual groups (cached)
 * @param proteinToOrganism: persisted protein-id -> organism-abbrev map (cached)
 * @param outdatedOrganisms: organisms to drop
 * @return stableGroups combined, filtered core+residual groups file
 * @return droppedMemberGroups groups that lost >=1 member (need a new best rep)
 */
process filterStableGroups {
  container = 'veupathdb/orthofinder:1.9.3'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path fullGroupFile
    path residualGroupFile
    path proteinToOrganism
    path outdatedOrganisms

  output:
    path 'stableGroups.txt', emit: stableGroups
    path 'droppedMemberGroups.txt', emit: droppedMemberGroups

  script:
    template 'filterStableGroups.bash'
}


/**
 * Diamond-search changed/removed/new-organism sequences against the cached,
 * pre-built full-proteome diamond database from the previous run -- no
 * database rebuild needed, since that cached .dmnd already indexes every
 * sequence in every stable group.
 */
process incrementalDiamond {
  container 'veupathdb/diamondsimilarity:1.0.0'

  input:
    path fasta
    path database
    val outputList

  output:
    path '*.out', emit: similarities
    path fasta, emit: fasta

  script:
    template 'incrementalDiamondSimilarity.bash'
}


/**
 * Assign each sequence to whichever stable group (core or residual) its best
 * Diamond hit belongs to. A sequence whose best hit landed on a sequence that
 * was filtered out (outdated organism) is treated as no-hit, same as a
 * sequence with no hit at all.
 */
process assignToStableGroups {
  container = 'veupathdb/orthofinder:1.9.3'

  input:
    path diamondInput
    path fasta
    path stableGroups

  output:
    path 'groups.txt', emit: groups
    path fasta, emit: fasta

  script:
    template 'assignToStableGroups.bash'
}


/**
 * Merge newly-assigned sequences into the filtered stable groups file.
 */
process mergeAssignedIntoStableGroups {
  container = 'veupathdb/orthofinder:1.9.3'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path stableGroups
    path assignments

  output:
    path 'updatedStableGroups.txt'

  script:
    template 'mergeAssignedIntoStableGroups.bash'
}


/**
 * A group is "touched" -- and needs its best representative recomputed --
 * if it lost a member (filterStableGroups) or gained one (newAssignments).
 * Untouched groups keep their cached best representative unchanged.
 */
process identifyTouchedGroups {
  input:
    path droppedMemberGroups
    path newAssignments

  output:
    path 'touchedGroups.txt'

  script:
    template 'identifyTouchedGroups.bash'
}


/**
 * Write one small fasta per touched group containing just its current
 * members, pulled from either this run's changed/new proteomes or the
 * previous run's cached full proteome (for members that didn't change).
 */
process splitTouchedGroupFastas {
  container = 'veupathdb/orthofinder:1.9.3'

  input:
    path groupFile
    path touchedGroups
    path currentProteome
    path previousFullProteome

  output:
    path 'touchedGroupFastas/*.fasta'

  script:
    template 'splitTouchedGroupFastas.bash'
}


/**
 * Self-diamond touched groups' (small) member sets to get fresh intra-group
 * pairwise similarity -- far cheaper than recomputing this for every group,
 * since only touched groups need it. Runs a batch of groups (one diamond
 * makedb+blastp per group, looped) in a single task rather than submitting
 * one cluster job per group -- with thousands of touched groups on an
 * incremental run, one-task-per-group badly oversubscribes the scheduler
 * relative to how many nodes are actually available.
 */
process selfDiamondGroup {
  container 'veupathdb/diamondsimilarity:1.0.0'

  input:
    path groupFastas
    val outputList

  output:
    path '*.sim'

  script:
    template 'selfDiamondGroup.bash'
}


/**
 * Pick a best representative per touched group from the fresh self-diamond
 * results, falling back to the sole member for any touched group that ended
 * up a singleton (no pairwise data at all).
 */
process findBestRepresentativesForTouchedGroups {
  container = 'veupathdb/orthofinder:1.9.3'

  input:
    path simFiles
    path touchedGroups
    path groupFile

  output:
    path 'touchedBestReps.txt', emit: bestReps
    path 'missingTouchedGroups.txt', emit: missingGroups

  script:
    template 'findBestRepresentativesForTouchedGroups.bash'
}


/**
 * Which organisms went through the core nextflow build (vs. peripheral) --
 * the core cache's own SpeciesIDs.txt is exactly that set. Needed to compute
 * the "core-only" group stats variant for touched groups.
 */
process extractCoreOrganisms {
  input:
    path coreSpeciesIds

  output:
    path 'coreOrganisms.txt'

  script:
    template 'extractCoreOrganisms.bash'
}


/**
 * Filter touched groups' self-diamond .sim files down to core-organism-only
 * pairs, for the "core-only" group stats variant. Runs a batch per task for
 * the same reason selfDiamondGroup does -- one task per touched group badly
 * oversubscribes the scheduler when there are thousands of them.
 */
process filterSimByCoreOrganisms {
  input:
    path simFiles
    path proteinToOrganism
    path coreOrganisms

  output:
    path '*.sim', includeInputs: true

  script:
    template 'filterSimByCoreOrganisms.bash'
}


/**
 * A touched group can have core+peripheral pairwise data but zero core-only
 * pairs (e.g. it now has only one core-organism member) -- so the "missing
 * groups" set for the core-only stats variant has to be recomputed against
 * the core-filtered .sim files specifically, not reused from the unfiltered set.
 */
process findMissingCoreSimGroups {
  input:
    path coreSimFiles
    path touchedGroups

  output:
    path 'missingCoreTouchedGroups.txt'

  script:
    template 'findMissingCoreSimGroups.bash'
}


/**
 * Merge freshly-recomputed touched-group representatives into the previous
 * run's cached best-representative mapping, split back into core/residual.
 *
 * mergedCoreBestReps.txt is published here (residual's own fasta gets built
 * from mergedResidualBestReps.txt further downstream instead) because it's
 * the comprehensive, mapping-format ("groupId\tseqId") equivalent of the
 * persistent cache's coreBestReps.txt -- nothing else in this run produces
 * that shape; coreBestReps.fasta is a derived fasta, not the mapping itself.
 */
process mergeBestReps {
  publishDir "$params.outputDir/", mode: "copy", pattern: "mergedCoreBestReps.txt"

  input:
    path cachedCoreBestReps
    path cachedResidualBestReps
    path touchedBestReps

  output:
    path 'mergedCoreBestReps.txt', emit: core
    path 'mergedResidualBestReps.txt', emit: residual

  script:
    template 'mergeBestReps.bash'
}


/**
 * Split the touched groups' freshly-computed best-representative rows by
 * group type -- core/peripheral (OG) stats/blast-value computation must never
 * see residual (OGR) rows and vice versa, since each type has its own
 * separate cached file and its own separate DB loader.
 */
process splitTouchedBestRepsByType {
  input:
    path touchedBestReps

  output:
    path 'touchedCoreBestReps.txt', emit: core
    path 'touchedResidualBestReps.txt', emit: residual

  script:
    template 'splitTouchedBestRepsByType.bash'
}


workflow incrementalWorkflow {
  take:
    changedOrNewProteomeDir  // tarball of changed/removed/new-organism proteomes, one fasta per organism
    previousFullProteome     // cached combined core+peripheral+residual proteome fasta from the previous run
    cachedCoreBestReps       // cached best representative per core+peripheral group
    cachedResidualBestReps   // cached best representative per residual group
    coreSpeciesIds           // cached core-only SpeciesIDs.txt (from the core nextflow build)
    cachedCoreStats          // cached core-only group stats
    cachedPeripheralStats    // cached core+peripheral group stats
    cachedIntraGroupBlastFile // cached intra-group (core+peripheral) blast values
    cachedResidualStats      // cached residual group stats
    cachedIntraResidualGroupBlastFile // cached intra-residual-group blast values

  main:
    // Organism identity for everything reprocessed this run -- extends the
    // persisted map so the next incremental run can filter by organism too.
    uncompressed = uncompressChangedFastas(changedOrNewProteomeDir)

    stable = filterStableGroups(params.fullGroupFile,
                                params.residualGroupFile,
                                params.proteinToOrganism,
                                params.outdatedOrganisms)

    similarities = incrementalDiamond(uncompressed.proteomes.flatten(),
                                      params.stableGroupsDatabase,
                                      params.orthoFinderDiamondOutputFields)

    assignResults = assignToStableGroups(similarities.similarities,
                                         similarities.fasta,
                                         stable.stableGroups.collect())

    // Per organism, split into "matched an existing stable group" vs "still
    // unassigned" (X) -- reusing the exact same core-vs-residual split logic
    // peripheralWorkflow already uses.
    split = splitAssignedAndResidual(assignResults.groups, assignResults.fasta)

    unassignedFasta = split.residualFasta.collectFile(name: 'unassigned.fasta', storeDir: params.outputDir)

    groupAssignments = assignResults.groups.collectFile(name: 'newAssignments.txt', storeDir: params.outputDir)

    updatedStableGroups = mergeAssignedIntoStableGroups(stable.stableGroups, groupAssignments)

    uncompressed.proteinToOrganism.collectFile(name: 'proteinToOrganism.tsv', storeDir: params.outputDir)

    // Recompute best representatives only for groups whose membership actually
    // changed (lost or gained a member); every other group keeps its cached
    // representative unchanged -- avoids recomputing intra-group similarity
    // for the whole core+peripheral+residual group set every run.
    touchedGroups = identifyTouchedGroups(stable.droppedMemberGroups, groupAssignments)

    currentFullProteome = combineProteomes(previousFullProteome, uncompressed.combinedProteomesFasta)

    touchedGroupFastas = splitTouchedGroupFastas(updatedStableGroups,
                                                 touchedGroups,
                                                 uncompressed.combinedProteomesFasta,
                                                 previousFullProteome)

    touchedGroupSimsList = selfDiamondGroup(touchedGroupFastas.flatten().collate(100), params.orthoFinderDiamondOutputFields).flatten()
    touchedGroupSims = touchedGroupSimsList.collect()

    touchedBestRepsResults = findBestRepresentativesForTouchedGroups(touchedGroupSims,
                                                                     touchedGroups,
                                                                     updatedStableGroups)

    mergedBestReps = mergeBestReps(cachedCoreBestReps, cachedResidualBestReps, touchedBestRepsResults.bestReps)

    makeCoreBestRepresentativesFasta(mergedBestReps.core, currentFullProteome)
    makeResidualBestRepresentativesFasta(mergedBestReps.residual, currentFullProteome)

    // A touched group can be core/peripheral (OG) or residual (OGR) -- core
    // and residual stats/blast-value files are separate caches with separate
    // DB loaders, so every "touched-only recompute" below must be scoped to
    // the right type or it either contaminates the wrong file or silently
    // never updates the right one.
    touchedRepsByType = splitTouchedBestRepsByType(touchedBestRepsResults.bestReps)

    // Group stats and intra-group blast values, recomputed for touched groups
    // only (using the same fresh self-diamond data just computed above for
    // best-rep selection) and merged with the cached values for every other
    // group -- same "touched-only recompute, merge with cache" pattern as
    // best-rep selection, so this never requires recomputing similarity for
    // the whole core+peripheral group set.
    touchedPeripheralStats = calculatePeripheralStatsForTouched(touchedRepsByType.core,
                                                                 touchedGroupSims,
                                                                 updatedStableGroups,
                                                                 makeEmptyFileForPeripheralStats(),
                                                                 touchedBestRepsResults.missingGroups,
                                                                 true)

    coreOrganisms = extractCoreOrganisms(coreSpeciesIds)

    touchedCoreSims = filterSimByCoreOrganisms(touchedGroupSimsList.collate(100),
                                               uncompressed.proteinToOrganism.first(),
                                               coreOrganisms.first()).flatten().collect()

    missingCoreTouchedGroups = findMissingCoreSimGroups(touchedCoreSims, touchedGroups)

    touchedCoreStats = calculateCoreStatsForTouched(touchedRepsByType.core,
                                                     touchedCoreSims,
                                                     updatedStableGroups,
                                                     makeEmptyFileForCoreStats(),
                                                     missingCoreTouchedGroups,
                                                     true)

    mergedPeripheralStats = mergePeripheralStatsByGroupId(cachedPeripheralStats, touchedGroups, touchedPeripheralStats)
    mergedPeripheralStats.collectFile(name: 'peripheral_stats.txt', storeDir: params.outputDir + '/groupStats')

    mergedCoreStats = mergeCoreStatsByGroupId(cachedCoreStats, touchedGroups, touchedCoreStats)
    mergedCoreStats.collectFile(name: 'core_stats.txt', storeDir: params.outputDir + '/groupStats')

    touchedIntraGroupBlastFile = createIntraGroupBlastFile(touchedGroupSims, makeEmptyFileForIntraGroupBlast(), touchedRepsByType.core)
    mergedIntraGroupBlastFile = mergeIntraGroupBlastByGroupId(cachedIntraGroupBlastFile, touchedGroups, touchedIntraGroupBlastFile)
    mergedIntraGroupBlastFile.collectFile(name: 'intraGroupBlastFile.tsv', storeDir: params.outputDir)

    // Same "touched-only recompute, merge with cache" treatment for the
    // residual side -- covers pre-existing residual groups that gained a
    // member this run (brand-new residual groups formed from the leftover
    // unassigned (X) sequences get their own stats from the chained
    // postResidualEntry run below, and are combined with this file's output
    // downstream in the ApiCommonWorkflow XML).
    touchedResidualStats = calculateResidualStatsForTouched(touchedRepsByType.residual,
                                                             touchedGroupSims,
                                                             updatedStableGroups,
                                                             touchedBestRepsResults.missingGroups)
    mergedResidualStats = mergeResidualStatsByGroupId(cachedResidualStats, touchedGroups, touchedResidualStats)
    mergedResidualStats.collectFile(name: 'mergedResidualStats.txt', storeDir: params.outputDir)

    touchedIntraResidualGroupBlastFile = createIntraResidualGroupBlastFileForTouched(touchedGroupSims,
                                                                                     makeEmptyFileForIntraResidualGroupBlast(),
                                                                                     touchedRepsByType.residual)
    mergedIntraResidualGroupBlastFile = mergeIntraResidualGroupBlastByGroupId(cachedIntraResidualGroupBlastFile, touchedGroups, touchedIntraResidualGroupBlastFile)
    mergedIntraResidualGroupBlastFile.collectFile(name: 'mergedIntraResidualGroupBlastFile.tsv', storeDir: params.outputDir)

    // Only the true leftovers (X) go through OrthoFinder clustering, via the
    // existing, unmodified residual workflow -- a small set instead of the
    // full accumulated residual pool.
    residualTarball = createCompressedResidualFastaDir(unassignedFasta, uncompressed.proteomeDir.collect())

    residualWorkflow(residualTarball.fastaDir)
}
