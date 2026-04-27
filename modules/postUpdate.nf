#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { bestRepsSelfDiamond; combineProteomes;
        } from './shared.nf'

include { mergeCoreAndResidualBestReps;
          combineGroupFiles;
          makeFullDiamondDatabaseWithGroups;
          previousGroups;
          filterResidualGroups;
          filterForCoreSequences;
          createFastGeneTrees;
        } from './postProcessing.nf'


/**
 * Merges the best rep fasta from a previous residual run with the best rep fasta
 * from the current update residual run into a single file.
 *
 * @param existingResidualBestReps: bestReps.fasta from the original postResidual run
 * @param newResidualBestReps: bestReps.fasta from the updateResidual run
 * @return mergedResidualBestReps.fasta
 */
process mergeResidualBestRepsFastas {
  container = 'veupathdb/orthofinder:1.9.3'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path existingResidualBestReps
    path 'newResidualBestReps.fasta'

  output:
    path 'mergedResidualBestReps.fasta'

  script:
    """
    cp $existingResidualBestReps mergedResidualBestReps.fasta
    cat newResidualBestReps.fasta >> mergedResidualBestReps.fasta
    """
}


/**
 * Merges the residual fasta from a previous residual run with the residual fasta
 * produced by the updateResidual run for building the full proteome.
 *
 * @param existingResidualFasta: residualFasta.fa from the original residual run
 * @param newResidualFasta: residualFasta.fa from the updateResidual run
 * @return mergedResidualFasta.fa
 */
process mergeResidualFastas {
  container = 'veupathdb/orthofinder:1.9.3'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path existingResidualFasta
    path 'newResidualFasta.fa'

  output:
    path 'mergedResidualFasta.fa'

  script:
    """
    cp $existingResidualFasta mergedResidualFasta.fa
    cat newResidualFasta.fa >> mergedResidualFasta.fa
    """
}


workflow postUpdateWorkflow {
  take:
    coreBestRepsFasta

  main:
    // Combine previous residual best reps with new residual best reps from updateResidual
    mergedResidualBestReps = mergeResidualBestRepsFastas(
        params.existingResidualBestRepsFasta,
        params.newResidualBestRepsFasta
    )

    // Merge core and all residual best reps for similar group detection
    coreAndResidualBestRepFasta = mergeCoreAndResidualBestReps(
        mergedResidualBestReps,
        coreBestRepsFasta
    )

    bestRepsSubset = coreAndResidualBestRepFasta.splitFasta(by: 1000, file: true)

    bestRepsSelfDiamond(bestRepsSubset, coreAndResidualBestRepFasta).collectFile(
        name: 'similar_groups.tsv', storeDir: params.outputDir
    )

    // Combine existing residual fasta with new residual fasta for the full proteome
    mergedResidualFasta = mergeResidualFastas(
        params.existingResidualFasta,
        params.newResidualFasta
    )

    // Build full updated proteome: updated core+peripheral + all residuals
    fullOrthoProteome = combineProteomes(
        Channel.fromPath(params.coreAndPeripheralProteome),
        mergedResidualFasta
    )

    // Combine updated peripheral groups with updated residual groups (old + new)
    combinedGroupFile = combineGroupFiles(
        params.updatedGroupsFile,
        params.updatedResidualGroupsFile
    )

    previousGroups(combinedGroupFile, params.oldGroupsFile)

    makeFullDiamondDatabaseWithGroups(fullOrthoProteome, combinedGroupFile, params.buildVersion)

    // Gene trees: updated peripheral groups and all residual groups (existing + new)
    updatedGroupFastas      = Channel.fromPath("${params.updatedGroupFastas}/*.fasta")
    existingResidualFastas  = Channel.fromPath("${params.existingResidualGroupFastas}/*.fasta")
    newResidualGroupFastas  = Channel.fromPath("${params.newResidualGroupFastas}/*.fasta")

    allResidualGroupFastas = existingResidualFastas.mix(newResidualGroupFastas)

    residualFiltered = filterResidualGroups(allResidualGroupFastas.collate(10000))

    coreFiltered = filterForCoreSequences(
        updatedGroupFastas.collate(1000),
        params.coreAndPeripheralProteome
    )

    //createFastGeneTrees(
    //    residualFiltered.fastas.mix(coreFiltered.filtered)
    //        .collect().flatten().collate(1000)
    //)
}
