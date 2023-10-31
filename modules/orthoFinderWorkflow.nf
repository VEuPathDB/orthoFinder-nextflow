#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { uncompressFastas; uncompressFastas as uncompressPeripheralFastas; orthoFinderSetup} from './shared.nf'

process createCompressedFastaDir {
  container = 'veupathdb/orthofinder'

  input:
    path inputFasta

  output:
    path 'fastas.tar.gz', emit: fastaDir
    stdout emit: complete

  script:
    template 'createCompressedFastaDir.bash'
}


// process uncompressAndMakeCoreFasta {
//   container = 'veupathdb/orthofinder'

//   input:
//     path coreDir

//   output:
//     path 'core.fasta'

//   script:
//     template 'uncompressAndMakeCoreFasta.bash'
// }


process createEmptyBlastDir {
  container = 'veupathdb/orthofinder'

  input:
    val stdin

  output:
    path 'emptyBlastDir'

  script:
    """
    mkdir emptyBlastDir
    """
}










process splitOrthogroupsFile {
  container = 'veupathdb/orthofinder'

  input:
    path results

  output:
    path 'OG*', emit: orthoGroupsFiles

  script:
    template 'splitOrthogroupsFile.bash'
}

















process combineSimilarOrthogroups {
  container = 'veupathdb/orthofinder'

  publishDir "$params.outputDir", mode: "copy"

  input:
    // Avoid file name collision
    path 'coreAndResidual.txt'
    path coreAndCore

  output:
    path 'similarOrthogroupsFinal.txt'

  script:
    """
    touch similarOrthogroupsFinal.txt
    cat coreAndResidual.txt >> similarOrthogroupsFinal.txt
    cat $coreAndCore >> similarOrthogroupsFinal.txt
    """
}


process createDatabase {
  container = 'veupathdb/orthofinder'

  input:
    path newdbfasta

  output:
    path 'newdb.dmnd'

  script:
    template 'createDatabase.bash'
}


process peripheralDiamond {
  container = 'veupathdb/diamondsimilarity'

  publishDir "$params.outputDir/newPeripheralDiamondCache", mode: "copy", pattern: "*.out"

  input:
    path fasta
    path database
    path peripheralDiamondCache
    val outputList

  output:
    path '*.out', emit: similarities


  script:
    template 'peripheralDiamondSimilarity.bash'
}


process assignGroups {
  container = 'veupathdb/orthofinder'

  input:
    path diamondInput
        
  output:
    path 'sortedGroups.txt', emit: groups
    path diamondInput, emit: similarities

  script:
    template 'assignGroups.bash'
}


process getPeripheralResultsToBestRep {
  container = 'veupathdb/orthofinder'
  
  input:
    path similarityResults
    path groupAssignments
        
  output:
    path '*.tsv', emit: groupSimilarities

  script:
    template 'getPeripheralResultsToBestRep.bash'
}


process makeResidualAndPeripheralFastas {
  container = 'veupathdb/orthofinder'

  publishDir params.outputDir, mode: "copy"
  
  input:
    path groups
    path seqFile
        
  output:
    path 'residuals.fasta', emit: residualFasta
    path 'peripherals.fasta', emit: peripheralFasta

  script:
    template 'makeResidualAndPeripheralFastas.bash'
}
 

process cleanPeripheralDiamondCache {
  container = 'veupathdb/orthofinder'

  input:
    path outdatedOrganisms
    path peripheralDiamondCache 

  output:
    path 'cleanedCache'

  script:
    template 'cleanPeripheralDiamondCache.bash'
}


process combineProteomes {
  container = 'veupathdb/orthofinder'

  input:
    path coreProteome
    path peripheralProteome

  output:
    path 'fullProteome.fasta'

  script:
    template 'combineProteomes.bash'
}


process makeGroupsFile {
  container = 'veupathdb/orthofinder'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path coreGroups
    path peripheralGroups

  output:
    path 'GroupsFile.txt'

  script:
    template 'makeGroupsFile.bash'
}


process splitProteomeByGroup {
  container = 'veupathdb/orthofinder'

  input:
    path proteome
    path groups
    path outdated

  output:
    path '*.fasta'

  script:
    template 'splitProteomeByGroup.bash'
}


process groupSelfDiamond {
  container = 'veupathdb/diamondsimilarity'

  publishDir "$params.outputDir/groupResults", mode: "copy", pattern: "*.out"

  input:
    path groupFasta
    val blastArgs

  output:
    path '*.out', emit: groupResults

  script:
    template 'groupSelfDiamond.bash'
}


process keepSeqIdsFromDeflines {
  container = 'veupathdb/orthofinder'

  input:
    path fastas

  output:
    path 'filteredFastas/*.fasta', optional: true

  script:
    template 'keepSeqIdsFromDeflines.bash'
}


process createGeneTrees {
  container = 'veupathdb/orthofinder'

  publishDir "$params.outputDir/geneTrees", mode: "copy"

  input:
    path fasta

  output:
    path '*.tree'

  script:
    template 'createGeneTrees.bash'
}






process calculatePeripheralGroupResults {
  container = 'veupathdb/orthofinder'

  publishDir "$params.outputDir/peripheralAndCoreGroupStats", mode: "copy"

  input:
    path groupResultsToBestReps
    val evalueColumn
    val isResidual

  output:
    path '*final.tsv'

  script:
    template 'calculateGroupResults.bash'
}




process mergeCoreAndResidualBestReps {
  container = 'veupathdb/orthofinder'

  input:
    path residualBestReps
    // Avoid file name collision
    path 'coreBestReps.fasta'

  output:
    path 'bestRepsFull.fasta'

  script:
    """
    touch bestRepsFull.fasta
    cat $residualBestReps >> bestRepsFull.fasta
    cat coreBestReps.fasta >> bestRepsFull.fasta
    """
}


process combinePeripheralAndCoreSimilaritiesToBestReps {
  container = 'veupathdb/orthofinder'

  input:
    path peripheralGroupSimilarities
    path coreGroupSimilarities

  output:
    path 'final/*'

  script:
    template 'combinePeripheralAndCoreSimilaritiesToBestReps.bash'
}


workflow peripheralWorkflow { 
  take:
    peripheralDir

  main:

    uncompressAndMakePeripheralFastaResults = uncompressPeripheralFastas(peripheralDir)
    uncompressAndMakeCoreFastaResults = uncompressFastas(params.coreProteomes)

    database = createDatabase(params.coreBestReps)
    cleanPeripheralDiamondCacheResults = cleanPeripheralDiamondCache(params.outdatedOrganisms, params.peripheralDiamondCache)

    // Run Diamond
    similarities = peripheralDiamond(uncompressAndMakePeripheralFastaResults.proteomes.flatten(), database, cleanPeripheralDiamondCacheResults, params.peripheralDiamondOutput)

    // Assigning Groups
    groupsAndSimilarities = assignGroups(similarities)

    groupAssignments = groupsAndSimilarities.groups.collectFile(name: 'groups.txt')

    // Calculating Core + Peripheral Group Similarity Results
    groupSimilarityResultsToBestRep = getPeripheralResultsToBestRep(groupsAndSimilarities.similarities, groupsAndSimilarities.groups)
    allGroupSimilarityResultsToBestRep = groupSimilarityResultsToBestRep.flatten().collectFile() { item -> [ item.getName(), item ] }

    combinePeripheralAndCoreSimilaritiesToBestRepsResults = combinePeripheralAndCoreSimilaritiesToBestReps(allGroupSimilarityResultsToBestRep.collect(), params.coreSimilarityResults)
    calculatePeripheralGroupResults(combinePeripheralAndCoreSimilaritiesToBestRepsResults.collect().flatten().collate(100), 1, false)

    // Create Peripherals And Residual Fastas
    makeResidualAndPeripheralFastasResults = makeResidualAndPeripheralFastas(groupAssignments, uncompressAndMakePeripheralFastaResults.combinedProteomesFasta)

    // Creating Vore + Peripheral Gene Trees
    combinedProteome = combineProteomes(uncompressAndMakeCoreFastaResults.combinedProteomesFasta, makeResidualAndPeripheralFastasResults.peripheralFasta)

    makeGroupsFileResults = makeGroupsFile(params.coreGroupsFile, groupAssignments)
    splitProteomesByGroupResults = splitProteomeByGroup(combinedProteome, makeGroupsFileResults.splitText( by: 100, file: true ), params.outdatedOrganisms)
    keepSeqIdsFromDeflinesResults = keepSeqIdsFromDeflines(splitProteomesByGroupResults.collect().flatten().collate(100))
    createGeneTrees(keepSeqIdsFromDeflinesResults.collect().flatten().collate(100))

  // Residual Processing

    // Prep For OrthoFinder
    compressedFastaDir = createCompressedFastaDir(makeResidualAndPeripheralFastasResults.residualFasta)
    emptyBlastDir = createEmptyBlastDir(compressedFastaDir.complete)
    emptyDir = emptyBlastDir.collect()
    proteomesForOrthofinder = moveUnambiguousAminoAcidSequencesFirst(compressedFastaDir.fastaDir)
    setup = orthoFinderSetup(proteomesForOrthofinder)

    speciesIds = speciesFileToList(setup.speciesMapping, 0);
    speciesNames = speciesFileToList(setup.speciesMapping, 1);

    // get all pairwise combinations of organisms
    pairsChannel = listToPairwiseComparisons(speciesIds, 100);

    // Run Diamond
    diamondResults = diamond(pairsChannel, setup.orthofinderWorkingDir.collect(), emptyDir, params.residualDiamondOutput)
    blasts = diamondResults.blast.collect()

    // Create Groups
    computeGroupResults = computeGroups(blasts, setup.orthofinderWorkingDir)

    speciesOrthologs = splitOrthologGroupsPerSpecies(speciesNames.flatten(), setup.speciesMapping.collect(), setup.sequenceMapping.collect(), computeGroupResults.orthologgroups.collect(), params.buildVersion);

    // Getting Pairwise Results Per Group
    diamondSimilaritiesPerGroup = makeOrthogroupDiamondFiles(pairsChannel, blasts, speciesOrthologs.orthologs.collect())
    allDiamondSimilaritiesPerGroup = diamondSimilaritiesPerGroup.flatten().collectFile() { item -> [ item.getName(), item ] }
    allDiamondSimilarities = allDiamondSimilaritiesPerGroup.collect()

    // Identifying Singletons
    singletonFiles = speciesOrthologs.singletons.collect()
    fullSingletonsFile = makeFullSingletonsFile(singletonFiles)

    // Best Representatives
    bestRepresentatives = findBestRepresentatives(allDiamondSimilaritiesPerGroup.collate(250))
    combinedBestRepresentatives = removeEmptyGroups(fullSingletonsFile.concat(bestRepresentatives).flatten().collectFile(name: "combined_best_representative.txt"))
    bestRepresentativeFasta = makeBestRepresentativesFasta(combinedBestRepresentatives, setup.orthofinderWorkingDir, true)

    // Residual Group Stats
    groupResultsOfBestRep = retrieveResultsToBestRepresentative(allDiamondSimilarities, combinedBestRepresentatives.splitText( by: 100, file: true ), fullSingletonsFile).collect()
    calculateGroupResults(groupResultsOfBestRep.flatten().collate(250), 10, true)

    // Similarity Between Orthogroups
    coreAndResidualBestRepFasta = mergeCoreAndResidualBestReps(bestRepresentativeFasta, params.coreBestReps)
    bestRepSubset = bestRepresentativeFasta.splitFasta(by:1000, file:true)

    // Residual to core and residuals
    residualBestRepsSelfDiamondResults = bestRepsSelfDiamond(bestRepSubset, coreAndResidualBestRepFasta.collect(), params.peripheralDiamondOutput)

    coreBestRepsChannel = Channel.fromPath( params.coreBestReps )
    coreBestRepSubset = coreBestRepsChannel.splitFasta(by:1000, file:true)

    // Core to residuals only
    coreToResidualBestRepsSelfDiamondResults = bestRepsSelfDiamondTwo(coreBestRepSubset, bestRepresentativeFasta.collect(), params.peripheralDiamondOutput)

    // Collect orthogroup similarity results
    allResidualBestRepsSelfDiamondResults = residualBestRepsSelfDiamondResults.collectFile()
    allCoreToResidualBestRepsSelfDiamondResults = coreToResidualBestRepsSelfDiamondResults.collectFile()

    // Format group similairity results
    formatSimilarOrthogroupsResults = formatSimilarOrthogroups(allResidualBestRepsSelfDiamondResults.concat(allCoreToResidualBestRepsSelfDiamondResults))

    // Combine residual vs core and residual, core vs residual and cached core vs core to get final results
    combineSimilarOrthogroups(formatSimilarOrthogroupsResults.collectFile(), params.coreSimilarOrthogroups)

}
