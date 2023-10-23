#!/usr/bin/env nextflow
nextflow.enable.dsl=2


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

process uncompressAndMakePeripheralFasta {
  container = 'veupathdb/orthofinder'

  input:
    path peripheralDir

  output:
    path 'fastas/*.fasta', emit: proteomes
    path 'peripheral.fasta', emit: peripheralFasta

  script:
    template 'uncompressAndMakePeripheralFasta.bash'
}


process uncompressAndMakeCoreFasta {
  container = 'veupathdb/orthofinder'

  input:
    path coreDir

  output:
    path 'core.fasta'

  script:
    template 'uncompressAndMakeCoreFasta.bash'
}


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


/**
 * ortho finder looks for unambiguous amino acid sequences first sequences of fasta
 * ensure the first sequence in each fasta file has unambigous amino acids
 * @param proteomes:  tar.gz directory of fasta files.  each named like $organismAbbrev.fasta
 * @return arrangedProteomes directory of fasta files
 *
 */
process moveUnambiguousAminoAcidSequencesFirst {
  container = 'veupathdb/orthofinder'

  input:
    path proteomes

  output:
    path 'cleanedFastas'

  script:
    template 'moveUnambiguousAminoAcidSequencesFirst.bash'
}


/**
 * orthofinder makes new primary key for protein sequences
 * this step makes new fastas and mapping files (species and sequence) and diamond index files
 * the species and sequence mapping files are published to diamondCache output directory
 * @param fastas:  directory of fasta files appropriate for orthofinder
 * @return orthofinderSetup directory containes mapped fastas, diamond indexes and mapping files
 * @return SpeciesIDs.txt file contains mappings from orthofinder primary keys to organism abbreviations
 * @return SequenceIDs.txt file contains mappings from orthofinder primary keys to gene/protein ids
 */


process orthoFinderSetup {
  container = 'veupathdb/orthofinder'

  publishDir "$params.outputDir/diamondCache", mode: "copy", pattern: "*.txt"

  input:
    path 'fastas'

  output:
    path 'OrthoFinder', emit: orthofinderDirectory
    path 'WorkingDirectory', emit: orthofinderWorkingDir, type: 'dir'
    path 'WorkingDirectory/SpeciesIDs.txt', emit: speciesMapping
    path 'WorkingDirectory/SequenceIDs.txt', emit: sequenceMapping

  script:
    template 'orthoFinder.bash'
}


/**
* will either take diamond results from mappedCache dir OR run diamond
* @param pair of integers.  There will be lots of these
* @param orthofinderWorkingDir is the direcotry with the diamond indexes and fasta files
* @param mappedBlastCache is the directory of previous blast output mapped to this run
* @return Blast*.txt is the resulting file (either from cache or new)
*/
process diamond {
  container = 'veupathdb/diamondsimilarity'

  publishDir "$params.outputDir/diamondCache", mode: "copy", pattern: "Blast*.txt"

  input:
    tuple val(target), val(queries)
    path orthofinderWorkingDir
    path mappedBlastCache
    val outputList

  output:
    path 'Blast*.txt', emit: blast

  script:
    template 'diamond.bash'
}


/**
 * organisms which are being updated by this run are set in a file in the nextflow config
 *  this step does a further check to ensure the sequence mapping file is identical;  if not it will add to the cache
 * (this step allows us to simplify the mapping from cache by allowing us to only map species/organisms.)
 * This step will loop through the Blast*.txt and change the file name and first 2 columns based on species id mapping
 * @param previousDiamondCacheDirectory is set in the nextflow config. it contains Blast files and Species/Sequence Mappings
 * @param outdatedOrganisms file contains on organism id per line and is used when we get an updated annotation for a core proteome
 * @param speciesMapping is the NEW Species mapping from orthofinder setup step (current run)
 * @param sequenceMapping is the NEW Sequence mapping from orthofinder setup step (current run)
 * @return outputDir contains a directory of Blast*.txt files with mapped ids
 */
process mapCachedBlasts {
    container = 'veupathdb/orthofinder'

    input:
    path previousDiamondCacheDirectory
    path outdatedOrganisms
    path speciesMapping
    path sequenceMapping

    output:
    path 'mappedCacheDir'

    script:
    template 'mapCachedBlasts.bash'
}


process computeGroups {
  container = 'veupathdb/orthofinder'

  publishDir "$params.outputDir", mode: "copy", pattern: "Results"

  input:
    path blasts
    path orthofinderWorkingDir

  output:
    path 'Results/Phylogenetic_Hierarchical_Orthogroups/N0.tsv', emit: orthologgroups
    path 'Results'

  script:
    template 'computeGroups.bash'
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


process makeFullSingletonsFile {
  container = 'veupathdb/orthofinder'

  input:
    path singletonFiles

  output:
    path 'singletonsFull.dat'

  script:
    template 'makeFullSingletonsFile.bash'
}


process translateSingletonsFile {
  container = 'veupathdb/orthofinder'

  input:
    path singletonsFile
    path sequenceMapping

  output:
    path 'translatedSingletons.dat'

  script:
    template 'translateSingletonsFile.bash'
}


process reformatGroupsFile {
  container = 'veupathdb/orthofinder'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path groupsFile
    path translatedSingletons
    val buildVersion

  output:
    path 'reformattedGroups.txt'

  script:
    template 'reformatGroupsFile.bash'
}


process makeOrthogroupDiamondFiles {
  container = 'veupathdb/orthofinder'

  input:
    tuple val(target), val(queries)
    path blasts
    path orthologs

  output:
    path '*.sim', emit: orthogroupblasts

  script:
    template 'makeOrthogroupDiamondFiles.bash'
}


process findBestRepresentatives {
  container = 'veupathdb/orthofinder'

  input:
    path groupData

  output:
    path 'best_representative.txt', emit: groupCalcs

  script:
    template 'findBestRepresentatives.bash'
}


process retrieveResultsToBestRepresentative {
  container = 'veupathdb/orthofinder'

  publishDir "$params.outputDir/groupStatsToBestReps", mode: "copy"

  input:
    path groupData
    path bestReps
    path singletons

  output:
    path '*.tsv'

  script:
    template 'retrieveResultsToBestRepresentative.bash'
}


process makeBestRepresentativesFasta {
  container = 'veupathdb/orthofinder'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path bestRepresentatives
    path orthofinderWorkingDir
    val isResidual

  output:
    path 'bestReps.fasta'

  script:
    template 'makeBestRepresentativesFasta.bash'
}


process bestRepsSelfDiamond {
  container = 'veupathdb/diamondsimilarity'

  input:
    path bestRepSubset
    path bestRepsFasta
    val blastArgs

  output:
    path 'bestReps.out'

  script:
    template 'bestRepsSelfDiamond.bash'
}


process bestRepsSelfDiamondTwo {
  container = 'veupathdb/diamondsimilarity'

  input:
    path bestRepSubset
    path bestRepsFasta
    val blastArgs

  output:
    path 'bestReps.out'

  script:
    template 'bestRepsSelfDiamond.bash'
}


process formatSimilarOrthogroups {
  container = 'veupathdb/orthofinder'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path bestRepsBlast

  output:
    path 'similarOrthogroups.txt'

  script:
    template 'formatSimilarOrthogroups.bash'
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
    path '*.out', emit: output_file


  script:
    template 'peripheralDiamondSimilarity.bash'
}


process assignGroups {
  container = 'veupathdb/orthofinder'

  publishDir params.outputDir, mode: "copy"
  
  input:
    path sortedResults
        
  output:
    path 'sortedGroups.txt', emit: groups
    path 'sortedResults.txt', emit: similarities

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

  publishDir "$params.outputDir/fastas", mode: "copy"

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
  publishDir "$params.outputDir/fastas", mode: "copy", pattern: "*.fasta"

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

  publishDir "$params.outputDir/fastas", mode: "copy"

  input:
    path fastas

  output:
    path 'filteredFastas/*.fasta'

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


process splitOrthologGroupsPerSpecies {
    container = 'veupathdb/orthofinder'

    input:
    val species
    path speciesMapping
    path sequenceMapping
    path orthologgroups
    val buildVersion

    output:
    path '*.orthologs', emit: orthologs
    path "*.singletons", emit: singletons

    script:
    template 'splitOrthologGroupsPerSpecies.bash'
}


process removeEmptyGroups {
    input:
    path f

    output:
    path "unique_${f}"

    script:
    """
    grep -v '^empty' $f> unique_${f}
    """
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


process calculateGroupResults {
  container = 'veupathdb/orthofinder'

  publishDir "$params.outputDir/groupStats", mode: "copy"

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


def listToPairwiseComparisons(list, chunkSize) {
    return list.map { it -> [it,it].combinations().findAll(); }
        .flatMap { it }
        .groupTuple(size: chunkSize, remainder:true)

}


def speciesFileToList(speciesMapping, index) {
    return speciesMapping
        .splitText(){it.tokenize(': ')[index]}
        .map { it.replaceAll("[\n\r]", "") }
        .toList()
}


workflow coreWorkflow { 
  take:
    inputFile

  main:
    proteomesForOrthofinder = moveUnambiguousAminoAcidSequencesFirst(inputFile)
    setup = orthoFinderSetup(proteomesForOrthofinder)
    mappedCachedBlasts = mapCachedBlasts(params.diamondSimilarityCache, params.outdatedOrganisms, setup.speciesMapping, setup.sequenceMapping);

    speciesIds = speciesFileToList(setup.speciesMapping, 0);
    speciesNames = speciesFileToList(setup.speciesMapping, 1);

    // process X number pairs at a time
    speciesPairsAsTuple = listToPairwiseComparisons(speciesIds, 100);

    diamondResults = diamond(speciesPairsAsTuple, setup.orthofinderWorkingDir.collect(), mappedCachedBlasts.collect(), params.orthoFinderDiamondOutput)
    collectedDiamondResults = diamondResults.blast.collect()
    orthofinderGroupResults = computeGroups(collectedDiamondResults, setup.orthofinderWorkingDir)

    speciesOrthologs = splitOrthologGroupsPerSpecies(speciesNames.flatten(), setup.speciesMapping.collect(), setup.sequenceMapping.collect(), orthofinderGroupResults.orthologgroups.collect(), params.buildVersion);

    diamondSimilaritiesPerGroup = makeOrthogroupDiamondFiles(speciesPairsAsTuple, collectedDiamondResults, speciesOrthologs.orthologs.collect())

    allDiamondSimilaritiesPerGroup = diamondSimilaritiesPerGroup.flatten().collectFile() { item -> [ item.getName(), item ] }

    allDiamondSimilarities = allDiamondSimilaritiesPerGroup.collect()
    singletonFiles = speciesOrthologs.singletons.collect()

    fullSingletonsFile = makeFullSingletonsFile(singletonFiles)

    translatedSingletonsFile = translateSingletonsFile(fullSingletonsFile, setup.sequenceMapping)

    reformatGroupsFile(orthofinderGroupResults.orthologgroups, translatedSingletonsFile, params.buildVersion)

    bestRepresentatives = findBestRepresentatives(allDiamondSimilaritiesPerGroup.collate(250))

    combinedBestRepresentatives = removeEmptyGroups(fullSingletonsFile.concat(bestRepresentatives).flatten().collectFile(name: "combined_best_representative.txt"))

    bestRepresentativeFasta = makeBestRepresentativesFasta(combinedBestRepresentatives, setup.orthofinderWorkingDir, false)

    groupResultsOfBestRep = retrieveResultsToBestRepresentative(allDiamondSimilarities, combinedBestRepresentatives.splitText( by: 1000, file: true ), fullSingletonsFile)

    calculateGroupResults(groupResultsOfBestRep.collect(), 10, false)

    bestRepSubset = bestRepresentativeFasta.splitFasta(by:1000, file:true)
    bestRepsSelfDiamondResults = bestRepsSelfDiamond(bestRepSubset, bestRepresentativeFasta, params.bestRepDiamondOutput)
    formatSimilarOrthogroups(bestRepsSelfDiamondResults.collectFile())

}


workflow peripheralWorkflow { 
  take:
    peripheralDir

  main:

  // Peripheral Processing

    // Prep
    uncompressAndMakePeripheralFastaResults = uncompressAndMakePeripheralFasta(peripheralDir)
    uncompressAndMakeCoreFastaResults = uncompressAndMakeCoreFasta(params.coreProteomes)

    // TODO;  this may be moved up to the core workflow if we do core v core
    database = createDatabase(params.coreBestReps)

    cleanPeripheralDiamondCacheResults = cleanPeripheralDiamondCache(params.outdatedOrganisms, params.peripheralDiamondCache)

    // Run Diamond
    peripheralDiamondResults = peripheralDiamond(uncompressAndMakePeripheralFastaResults.proteomes.flatten(), database, cleanPeripheralDiamondCacheResults, params.peripheralDiamondOutput)

    // Assigning Groups
    assignGroupsResults = assignGroups(peripheralDiamondResults)

    groupAssignments = assignGroupsResults.groups.collectFile(name: 'groups.txt')
    //similarityResults = assignGroupsResults.similarities.collectFile(name: 'sorted.out')

    // Calculating Core + Peripheral Group Similarity Results
    groupSimilarityResultsToBestRep = getPeripheralResultsToBestRep(assignGroupsResults.similarities, assignGroupsResults.groups)
    allGroupSimilarityResultsToBestRep = groupSimilarityResultsToBestRep.flatten().collectFile() { item -> [ item.getName(), item ] }
    combinePeripheralAndCoreSimilaritiesToBestRepsResults = combinePeripheralAndCoreSimilaritiesToBestReps(allGroupSimilarityResultsToBestRep.collect(), params.coreSimilarityResults)
    calculatePeripheralGroupResults(combinePeripheralAndCoreSimilaritiesToBestRepsResults, 1, false)

    // Create Peripherals And Residual Fastas
    makeResidualAndPeripheralFastasResults = makeResidualAndPeripheralFastas(groupAssignments, uncompressAndMakePeripheralFastaResults.peripheralFasta)

    // Creating Vore + Peripheral Gene Trees
    combinedProteome = combineProteomes(uncompressAndMakeCoreFastaResults, makeResidualAndPeripheralFastasResults.peripheralFasta)
    makeGroupsFileResults = makeGroupsFile(params.coreGroupsFile, groupAssignments)
    splitProteomesByGroupResults = splitProteomeByGroup(combinedProteome, makeGroupsFileResults, params.outdatedOrganisms)
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
    groupResultsOfBestRep = retrieveResultsToBestRepresentative(allDiamondSimilarities, combinedBestRepresentatives.splitText( by: 1, file: true ), fullSingletonsFile) 
    calculateGroupResults(groupResultsOfBestRep, 10, true)

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
