#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { uncompressFastas as uncompressChangedFastas;
          makeResidualAndPeripheralFastas as splitAssignedAndResidual;
        } from './shared.nf'
include { createCompressedResidualFastaDir } from './peripheral.nf'
include { residualWorkflow } from './residual.nf'


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


workflow incrementalWorkflow {
  take:
    changedOrNewProteomeDir  // tarball of changed/removed/new-organism proteomes, one fasta per organism

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

    unassignedFasta = split.residuals.collectFile(name: 'unassigned.fasta', storeDir: params.outputDir)

    groupAssignments = assignResults.groups.collectFile(name: 'newAssignments.txt')

    mergeAssignedIntoStableGroups(stable.stableGroups, groupAssignments)

    uncompressed.proteinToOrganism.collectFile(name: 'proteinToOrganism.tsv', storeDir: params.outputDir)

    // Only the true leftovers (X) go through OrthoFinder clustering, via the
    // existing, unmodified residual workflow -- a small set instead of the
    // full accumulated residual pool.
    residualTarball = createCompressedResidualFastaDir(unassignedFasta, uncompressed.proteomeDir.collect())

    residualWorkflow(residualTarball.fastaDir)
}
