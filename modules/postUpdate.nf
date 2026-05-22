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


workflow postUpdateWorkflow {
  take:
    coreBestRepsFasta

  main:
    // All residual best reps come directly from updateResidualEntry (existing + new were
    // re-run together, so this is the complete set under the new residualBuildVersion).
    residualBestRepsFasta = Channel.fromPath(params.residualBestRepsFasta).first()

    // Merge core and residual best reps for similar group detection
    coreAndResidualBestRepFasta = mergeCoreAndResidualBestReps(
        residualBestRepsFasta,
        coreBestRepsFasta
    )

    bestRepsSubset = coreAndResidualBestRepFasta.splitFasta(by: 1000, file: true)

    bestRepsSelfDiamond(bestRepsSubset, coreAndResidualBestRepFasta).collectFile(
        name: 'similar_groups.tsv', storeDir: params.outputDir
    )

    // Full residuals fasta comes directly from updateResidualEntry (all residuals re-run)
    residualFasta = Channel.fromPath(params.residualFasta).first()

    // Build full updated proteome: updated core+peripheral + all residuals
    fullOrthoProteome = combineProteomes(
        Channel.fromPath(params.coreAndPeripheralProteome),
        residualFasta
    )

    // Combine updated peripheral groups with updated residual groups
    combinedGroupFile = combineGroupFiles(
        params.updatedGroupsFile,
        params.updatedResidualGroupsFile
    )

    previousGroups(combinedGroupFile, params.oldGroupsFile)

    makeFullDiamondDatabaseWithGroups(fullOrthoProteome, combinedGroupFile, params.buildVersion)

    // Gene trees: updated peripheral groups and all residual groups (complete re-run)
    updatedGroupFastas    = Channel.fromPath("${params.updatedGroupFastas}/*.fasta")
    allResidualGroupFastas = Channel.fromPath("${params.residualGroupFastas}/*.fasta")

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
