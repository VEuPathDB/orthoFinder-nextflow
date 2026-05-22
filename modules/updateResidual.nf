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
 * Adds the existing residuals fasta into the new-residuals tar so OrthoFinder
 * sees all residual sequences together and assigns them all to the new version.
 *
 * @param newResidualFastasTar  tar.gz of per-organism fasta files for new residuals
 * @param existingResidualsFasta  combined residuals.fasta from the previous run
 * @return combinedResiduals.tar.gz  tar with existing residuals added as one extra file
 */
process addExistingResidualsToFastasDir {
  container = 'veupathdb/orthofinder:1.9.3'

  input:
    path newResidualFastasTar
    path 'existingResiduals.fasta'

  output:
    path 'combinedResiduals.tar.gz'

  script:
    """
    tar -xzf $newResidualFastasTar
    tarDir=\$(tar -tzf $newResidualFastasTar | head -1 | cut -d/ -f1)
    cp existingResiduals.fasta \${tarDir}/existingResiduals.fasta
    tar -czf combinedResiduals.tar.gz \${tarDir}
    """
}


/**
 * Publishes the reformatted residual groups as updatedResidualGroups.txt so
 * downstream cache and mapping steps find it at the expected path.
 */
process publishAsUpdatedResidualGroups {
  container = 'veupathdb/orthofinder:1.9.3'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path 'reformattedGroups.txt'

  output:
    path 'updatedResidualGroups.txt'

  script:
    """
    cp reformattedGroups.txt updatedResidualGroups.txt
    """
}


workflow updateResidualWorkflow {
  take:
    newResidualFastaDir
    existingResidualFasta

  main:
    // Combine existing residuals with new-organism residuals so OrthoFinder
    // re-groups everything under the new residualBuildVersion prefix.
    combinedFastaDir = addExistingResidualsToFastasDir(newResidualFastaDir, existingResidualFasta)

    // Prepare combined residual proteomes for OrthoFinder
    proteomesForOrthofinder = moveUnambiguousAminoAcidSequencesFirst(combinedFastaDir).collect()

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

    // Publish the complete new residual groups (all OGR${buildVersion}r${newResidualBuildVersion}_*)
    // as updatedResidualGroups.txt, fully replacing the previous residual groups.
    publishAsUpdatedResidualGroups(newResidualGroupsFile.groups)
}
