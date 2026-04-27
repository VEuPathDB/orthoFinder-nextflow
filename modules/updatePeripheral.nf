#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { calculateGroupStats;
          uncompressFastas as uncompressNewPeripheralFastas;
          uncompressFastas as uncompressCoreProteomes;
          combineProteomes;
        } from './shared.nf'

include { createDatabase;
          peripheralDiamond;
          assignGroups;
          makeResidualAndPeripheralFastas;
          makePeripheralOrthogroupDiamondFiles;
          combinePeripheralAndCoreSimilarities;
          checkForMissingGroups;
          createCompressedResidualFastaDir;
          splitProteomeByGroup;
        } from './peripheral.nf'


/**
 * Extends an existing GroupsFile.txt with new peripheral group assignments.
 * The input is staged under a different name to avoid the filename collision that
 * would occur if both the input and output were named GroupsFile.txt, which causes
 * the Perl script to truncate the input before reading it.
 *
 * @param existingGroupsFile: The current GroupsFile.txt (core + previous peripheral)
 * @param peripheralGroups: Tab-separated file of new peripheral seqID -> groupID assignments
 * @return GroupsFile.txt with new peripheral sequences appended to their groups
 */
process makeUpdatedGroupsFile {
  container = 'veupathdb/orthofinder:1.9.3'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path 'existingGroupsFile.txt'
    path peripheralGroups

  output:
    path 'GroupsFile.txt'

  script:
    """
    makeGroupsFile.pl --coreGroup existingGroupsFile.txt \
                      --peripheralGroup $peripheralGroups \
                      --output GroupsFile.txt
    """
}


/**
 * Creates an empty directory to serve as a no-op diamond cache for new organisms
 * that have no previously cached blast results.
 */
process createEmptyCache {
  container = 'veupathdb/orthofinder:1.9.3'

  output:
    path 'emptyCache'

  script:
    """
    mkdir emptyCache
    """
}


workflow updatePeripheralWorkflow {
  take:
    newPeripheralDir

  main:
    // Uncompress new peripheral proteomes and core proteomes
    newPeripheralFastas = uncompressNewPeripheralFastas(newPeripheralDir)
    coreProteomeFastas  = uncompressCoreProteomes(params.coreProteomes)

    // Build diamond database from all core proteins
    database   = createDatabase(coreProteomeFastas.combinedProteomesFasta)
    emptyCache = createEmptyCache()

    // Blast each new peripheral organism against the core database.
    // New organisms have no cached results so an empty cache is provided.
    similarities = peripheralDiamond(
        newPeripheralFastas.proteomes.flatten(),
        database,
        emptyCache,
        params.orthoFinderDiamondOutputFields
    )

    // Assign each new peripheral protein to a core group via lowest e-value hit
    groupsAndSimilarities = assignGroups(
        similarities.similarities,
        similarities.fasta,
        params.coreGroupsFile
    )

    // Partition new sequences into assigned (peripheral) and unassigned (residual)
    residualAndPeripheralFastas = makeResidualAndPeripheralFastas(
        groupsAndSimilarities.groups,
        groupsAndSimilarities.fasta
    )

    residualFasta = residualAndPeripheralFastas.residualFasta.collectFile(
        name: 'residuals.fasta', storeDir: params.outputDir
    )
    peripheralFasta = residualAndPeripheralFastas.peripheralFasta.collectFile(
        name: 'peripherals.fasta', storeDir: params.outputDir
    )

    newGroupAssignments = groupsAndSimilarities.groups.collectFile(name: 'groups.txt')

    // Extend the existing groups file with new peripheral assignments.
    // The existing GroupsFile.txt (core + previous peripheral) is treated as
    // the "coreGroups" base so that new sequences are appended to current groups.
    updatedGroupsFile = makeUpdatedGroupsFile(params.existingGroupsFile, newGroupAssignments)

    // Combine existing peripheral diamond cache with new blast results so that
    // stats can be recalculated across all groups (not just those with new members).
    existingBlasts      = Channel.fromPath("${params.peripheralDiamondCache}/*.out")
    allPeripheralBlasts = existingBlasts.mix(similarities.similarities).collectFile(name: 'blasts.out')

    // Split all peripheral blast results by group using the updated groups file
    peripheralBlastsByGroup = makePeripheralOrthogroupDiamondFiles(
        allPeripheralBlasts,
        updatedGroupsFile.collect()
    )

    // Combine peripheral per-group similarities with core per-group similarities
    allSimilarities = combinePeripheralAndCoreSimilarities(
        peripheralBlastsByGroup.collect(),
        params.coreGroupSimilarities
    ).collect()

    missingGroups = checkForMissingGroups(
        allSimilarities,
        params.buildVersion,
        updatedGroupsFile.collect()
    ).collect()

    // Recalculate group stats using the existing best representatives.
    // Best reps are intentionally NOT recalculated for an update run.
    existingBestReps = Channel.fromPath(params.existingBestReps)
    calculateGroupStats(
        existingBestReps,
        allSimilarities,
        updatedGroupsFile,
        params.coreTranslateSequenceFile,
        missingGroups,
        true
    ).collectFile(name: "updated_peripheral_stats.txt", storeDir: params.outputDir + "/groupStats")

    // Combine previous full proteome with new peripheral sequences to get
    // the updated proteome that includes all organisms
    updatedCombinedProteome = combineProteomes(
        Channel.fromPath(params.existingFullProteome),
        peripheralFasta
    )

    // Regenerate per-group fastas from the updated proteome for PostUpdate gene trees
    splitProteomeByGroup(updatedCombinedProteome.collect(), updatedGroupsFile)

    // Package new residual sequences for the UpdateResidual workflow
    peripheralProteomeDir = newPeripheralFastas.proteomeDir.collect()
    createCompressedResidualFastaDir(residualFasta, peripheralProteomeDir)
}
