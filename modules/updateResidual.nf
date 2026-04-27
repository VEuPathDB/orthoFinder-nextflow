#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { listToPairwiseComparisons; makeDiamondResultsFile;
          moveUnambiguousAminoAcidSequencesFirst; orthoFinderSetup;
          speciesFileToList; diamond;
          makeOrthogroupDiamondFile;
          splitOrthologGroupsPerSpecies;
        } from './shared.nf'

include { createResidualFasta; computeResidualGroups; createEmptyDir } from './residual.nf'

include { splitProteomeByGroup;
          makeFullResidualSingletonsFile;
          reformatResidualGroupsFile;
          findResidualBestRepresentatives;
          removeEmptyGroups;
          makeResidualBestRepresentativesFasta;
          translateBestRepsFile;
          addFirstSeqForGroupsWithNoBestRep;
          checkForMissingGroups;
          calculateResidualGroupStats;
          createIntraResidualGroupBlastFile;
        } from './postResidual.nf'


/**
 * Appends newly created residual groups to the existing reformatted residual
 * groups file so downstream consumers see all groups in one place.
 *
 * @param existingGroups: Reformatted residual groups from a previous postResidual run
 * @param newGroups: Reformatted residual groups produced by this update run
 * @return updatedResidualGroups.txt  Combined groups file with old and new entries
 */
process appendNewResidualGroups {
  container = 'veupathdb/orthofinder:1.9.3'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path existingGroups
    path 'newGroups.txt'

  output:
    path 'updatedResidualGroups.txt'

  script:
    """
    cp $existingGroups updatedResidualGroups.txt
    cat newGroups.txt >> updatedResidualGroups.txt
    """
}


workflow updateResidualWorkflow {
  take:
    newResidualFastaDir

  main:
    // Prepare new residual proteomes for OrthoFinder (same steps as residual workflow)
    proteomesForOrthofinder = moveUnambiguousAminoAcidSequencesFirst(newResidualFastaDir).collect()

    // Combine all new residual proteins into a single fasta
    newResidualFasta = createResidualFasta(proteomesForOrthofinder)

    // OrthoFinder internal setup: creates working directory, species/sequence mappings
    setup = orthoFinderSetup(proteomesForOrthofinder)

    // New residuals have no cached blast results
    emptyCache = createEmptyDir(setup.speciesMapping).collect()

    speciesIds   = speciesFileToList(setup.speciesMapping, 0)
    speciesNames = speciesFileToList(setup.speciesMapping, 1)

    speciesPairsAsTuple = listToPairwiseComparisons(speciesIds, 500)

    diamondResults = diamond(
        speciesPairsAsTuple,
        setup.orthofinderWorkingDir.collect(),
        emptyCache,
        params.orthoFinderDiamondOutputFields
    )

    collectedDiamondResults = diamondResults.blast.collect()

    diamondResultsFile = makeDiamondResultsFile(collectedDiamondResults)

    // Run OrthoFinder to cluster new residual proteins into groups
    newResidualOrthoGroups = computeResidualGroups(collectedDiamondResults, setup.orthofinderWorkingDir)

    // Reformat new group names with the new residualBuildVersion so they are
    // distinct from groups produced in previous residual runs (e.g. OGR7r2_*)
    newResidualGroupsFile = reformatResidualGroupsFile(
        newResidualOrthoGroups.orthologgroups,
        params.buildVersion,
        params.newResidualBuildVersion
    )

    // Split new residual proteome by group for PostUpdate gene trees
    splitProteomeByGroup(
        newResidualFasta,
        newResidualGroupsFile.groups.splitText(by: 10000, file: true)
    )

    // Per-species ortholog/singleton files needed for best rep identification
    speciesOrthologs = splitOrthologGroupsPerSpecies(
        speciesNames.flatten(),
        setup.speciesMapping,
        setup.sequenceMapping,
        newResidualOrthoGroups.orthologgroups.collect(),
        params.buildVersion,
        params.newResidualBuildVersion,
        "residual"
    )

    // Per-group diamond similarity files for the new residual groups
    diamondSimilaritiesPerGroup = makeOrthogroupDiamondFile(
        diamondResultsFile.collect(),
        speciesOrthologs.orthologs.collectFile(name: 'orthologs.txt')
    )

    allDiamondSimilarities = diamondSimilaritiesPerGroup.blastsByOrthogroup.flatten().collect()

    singletonFiles = speciesOrthologs.singletons.collect()

    // Find the best representative for each new residual group
    bestRepresentatives = findResidualBestRepresentatives(
        diamondSimilaritiesPerGroup.blastsByOrthogroup.flatten().collate(250),
        newResidualGroupsFile.groups.collect(),
        setup.sequenceMapping
    )

    allBestRepresentatives = bestRepresentatives.flatten().collectFile()

    singletonsFull = makeFullResidualSingletonsFile(singletonFiles, params.buildVersion).collectFile()

    combinedBestRepresentatives = removeEmptyGroups(singletonsFull, allBestRepresentatives)

    // Translate OrthoFinder internal sequence IDs to actual sequence IDs
    translatedBestRepsFile = translateBestRepsFile(
        setup.sequenceMapping,
        combinedBestRepresentatives,
        "residual"
    )

    // Ensure every group has a best rep, falling back to the first listed sequence
    completeBestRepsFile = addFirstSeqForGroupsWithNoBestRep(
        newResidualGroupsFile.groups,
        translatedBestRepsFile
    )

    createIntraResidualGroupBlastFile(
        diamondSimilaritiesPerGroup.collect(),
        setup.sequenceMapping,
        completeBestRepsFile
    )

    // Best reps fasta for new residual groups; consumed by PostUpdate
    makeResidualBestRepresentativesFasta(completeBestRepsFile, newResidualFasta)

    missingGroups = checkForMissingGroups(
        allDiamondSimilarities.flatten().collect(),
        params.buildVersion,
        params.newResidualBuildVersion,
        newResidualGroupsFile.groups
    ).collect()

    calculateResidualGroupStats(
        combinedBestRepresentatives,
        allDiamondSimilarities,
        newResidualGroupsFile.groups,
        missingGroups
    ).collectFile(name: "new_residual_stats.txt", storeDir: params.outputDir + "/groupStats")

    // Append new residual groups to the existing reformatted residual groups file.
    // The combined file contains OGR7r1_* (existing) and OGR7r2_* (new) entries.
    appendNewResidualGroups(params.existingResidualGroupsFile, newResidualGroupsFile.groups)
}
