#!/usr/bin/env nextflow
nextflow.enable.dsl=2


process createCompressedFastaDir {
  container = 'jbrestel/orthofinder'

  input:
    path inputFasta

  output:
    path 'fastas.tar.gz', emit: fastaDir
    stdout emit: complete

  script:
    template 'createCompressedFastaDir.bash'
}


process createEmptyBlastDir {
  container = 'jbrestel/orthofinder'

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
  container = 'jbrestel/orthofinder'

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
  container = 'jbrestel/orthofinder'

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
    val pair
    path orthofinderWorkingDir
    path mappedBlastCache

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
    container = 'jbrestel/orthofinder'

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
  container = 'jbrestel/orthofinder'

  publishDir "$params.outputDir", mode: "copy", pattern: "Results"

  input:
    path blasts
    path orthofinderWorkingDir

  output:
    path 'Results', emit: results
    path 'Results/Orthogroups/Orthogroups.txt', emit: orthologgroups

  script:
    template 'computeGroups.bash'
}


process splitOrthogroupsFile {
  container = 'jbrestel/orthofinder'

  input:
    path results

  output:
    path 'OG*', emit: orthoGroupsFiles

  script:
    template 'splitOrthogroupsFile.bash'
}

process makeOrthogroupSpecificFiles {
  container = 'jbrestel/orthofinder'

  publishDir "$params.outputDir/GroupResults", mode: "copy"

  input:
    path orthoGroupsFile
    path diamondFiles
    path sequenceMapping

  output:
    path 'OrthoGroup*', emit: orthogroups, optional: true
    path 'Singletons.dat', emit: singletons, optional: true

  script:
    template 'makeOrthogroupSpecificFiles.bash'
}

process orthogroupStatistics {
  container = 'jbrestel/orthofinder'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path groupData
    path results

  output:
    path '*.tsv', emit: groupStats

  script:
    template 'orthogroupStatistics.bash'
}

process orthogroupCalculations {
  container = 'jbrestel/orthofinder'

  input:
    path groupData

  output:
    path '*.final', emit: groupCalcs

  script:
    template 'orthogroupCalculations.bash'
}

process makeBestRepresentativesFasta {
  container = 'jbrestel/orthofinder'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path bestReps
    path sequenceMapping
    path fasta
    path singletons

  output:
    path 'bestReps.fasta'

  script:
    template 'makeBestRepresentativesFasta.bash'
}

process bestRepsSelfDiamond {
  container = 'veupathdb/diamondsimilarity'

  input:
    path bestRepsFasta
    val blastArgs

  output:
    path '*.out'

  script:
    template 'bestRepsSelfDiamond.bash'
}

process formatSimilarOrthogroups {
  container = 'jbrestel/orthofinder'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path bestRepsBlast

  output:
    path 'similarOrthogroups.txt'

  script:
    template 'formatSimilarOrthogroups.bash'
}


process createDatabase {
  container = 'rdemko2332/orthofinderperipheraltocore'

  input:
    path newdbfasta

  output:
    path 'newdb.dmnd'

  script:
    template 'createDatabase.bash'
}

process diamondSimilarity {
  container = 'rdemko2332/orthofinderperipheraltocore'

  input:
    path fasta
    path database
    val diamondArgs 

  output:
    path 'diamondSimilarity.out', emit: output_file

  script:
    template 'diamondSimilarity.bash'
}

process sortResults {
  container = 'rdemko2332/orthofinderperipheraltocore'

  input:
    path output
        
  output:
    path 'diamondSimilarity.out'

  script:
    """
    cat $output | sort -k 1 > diamondSimilarity.out
    """
}

process assignGroups {
  container = 'rdemko2332/orthofinderperipheraltocore'

  publishDir params.outputDir, mode: "copy"
  
  input:
    path sortedResults
        
  output:
    path 'groups.txt'

  script:
    template 'assignGroups.bash'
}

process makeResidualAndPeripheralFastas {
  container = 'rdemko2332/orthofinderperipheraltocore'

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
 

process cleanCache {
  container = 'rdemko2332/orthofinder'

  input:
    path updateList

  output:
    path 'done.txt'

  script:
    template 'cleanCache.bash'
}

process combineProteomes {
  container = 'rdemko2332/orthofinder'

  input:
    path coreProteome
    path peripheralProteome
    path cleanCache

  output:
    path 'fullProteome.fasta'

  script:
    template 'combineProteomes.bash'
}

process makeGroupsFile {
  container = 'rdemko2332/orthofinder'

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
  container = 'rdemko2332/orthofinder'

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
  container = 'rdemko2332/orthofinder'

  publishDir "$params.outputDir/fastas", mode: "copy"

  input:
    path fastas

  output:
    path 'filteredFastas/*.fasta'

  script:
    template 'keepSeqIdsFromDeflines.bash'
}


process createGeneTrees {
  container = 'rdemko2332/orthofinder'

  //publishDir "$params.outputDir", mode: "copy"

  input:
    path fasta

  output:
    path '*.fas'

  script:
    template 'createGeneTrees.bash'
}


workflow coreWorkflow { 
  take:
    inputFile

  main:
    proteomesForOrthofinder = moveUnambiguousAminoAcidSequencesFirst(inputFile)
    setup = orthoFinderSetup(proteomesForOrthofinder)
    mappedCachedBlasts = mapCachedBlasts(params.diamondSimilarityCache, params.outdatedOrganisms, setup.speciesMapping, setup.sequenceMapping);
    // get all pairwise combinations of organisms
    pairsChannel = setup.speciesMapping.splitText(){it.tokenize(':')[0]}.toList().map { it -> [it,it].combinations().findAll(); }.flatten().collate(2)
    diamondResults = diamond(pairsChannel, setup.orthofinderWorkingDir.collect(), mappedCachedBlasts.collect())
    blasts = diamondResults.blast.collect()
    computeGroupResults = computeGroups(blasts, setup.orthofinderWorkingDir)
    // TODO:  How many groups to process at a time?
    orthologGroupSubset = computeGroupResults.orthologgroups.splitText(by: 100, file: true)
    makeOrthogroupSpecificFilesResults = makeOrthogroupSpecificFiles(orthologGroupSubset, blasts, setup.sequenceMapping)
    orthogroupCalculationsResults = orthogroupCalculations(makeOrthogroupSpecificFilesResults.orthogroups.flatten().collate(250))
    makeBestRepresentativesFastaResults = makeBestRepresentativesFasta(orthogroupCalculationsResults, setup.sequenceMapping, inputFile, makeOrthogroupSpecificFilesResults.singletons)

    bestRepsSelfDiamondResults = bestRepsSelfDiamond(makeBestRepresentativesFastaResults, params.blastArgs)
    formatSimilarOrthogroups(bestRepsSelfDiamondResults)
    
}

workflow peripheralWorkflow { 
  take:
    peripheralFasta

  main:

    // PeripheralToCore
    database = createDatabase(params.coreBestReps)
    seqs = peripheralFasta.splitFasta( by:params.fastaSubsetSize, file:true  )
    diamondSimilarityResults = diamondSimilarity(seqs, database, params.diamondArgs)
    similarityResults = diamondSimilarityResults.output_file | collectFile(name: 'similarity.out')
    sortedResults = sortResults(similarityResults)
    assignGroupsResults = assignGroups(sortedResults)
    makeResidualAndPeripheralFastasResults = makeResidualAndPeripheralFastas(assignGroupsResults, peripheralFasta)

    // Residuals
    compressedFastaDir = createCompressedFastaDir(makeResidualAndPeripheralFastasResults.residualFasta)
    emptyBlastDir = createEmptyBlastDir(compressedFastaDir.complete)
    emptyDir = emptyBlastDir.collect()
    proteomesForOrthofinder = moveUnambiguousAminoAcidSequencesFirst(compressedFastaDir.fastaDir)
    setup = orthoFinderSetup(proteomesForOrthofinder)
    // // get all pairwise combinations of organisms
    pairsChannel = setup.speciesMapping.splitText(){it.tokenize(':')[0]}.toList().map { it -> [it,it].combinations().findAll(); }.flatten().collate(2)
    diamondResults = diamond(pairsChannel, setup.orthofinderWorkingDir.collect(), emptyDir)
    blasts = diamondResults.blast.collect()
    computeGroupResults = computeGroups(blasts, setup.orthofinderWorkingDir)

    orthologGroupSubset = computeGroupResults.orthologgroups.splitText(by: 100, file: true)

    makeOrthogroupSpecificFilesResults = makeOrthogroupSpecificFiles(orthologGroupSubset, blasts, setup.sequenceMapping)
    orthogroupCalculationsResults = orthogroupCalculations(makeOrthogroupSpecificFilesResults.orthogroups.flatten().collate(250))
    makeBestRepresentativesFastaResults =  makeBestRepresentativesFasta(orthogroupCalculationsResults, setup.sequenceMapping, peripheralFasta, makeOrthogroupSpecificFilesResults.singletons)

    // Groups
    cleanCacheResults = cleanCache(params.updateList)
    combinedProteome = combineProteomes(params.coreProteome, makeResidualAndPeripheralFastasResults.peripheralFasta, cleanCacheResults)
    makeGroupsFileResults = makeGroupsFile(params.coreGroupsFile, assignGroupsResults)
    splitProteomesByGroupResults = splitProteomeByGroup(combinedProteome, makeGroupsFileResults, params.updateList)
    keepSeqIdsFromDeflinesResults = keepSeqIdsFromDeflines(splitProteomesByGroupResults.collect().flatten().collate(100))
    keepSeqIdsFromDeflinesResults.collect()
    createGeneTrees(keepSeqIdsFromDeflinesResults.flatten())
    //groupSelfDiamondResults = groupSelfDiamond(keepSeqIdsFromDeflinesResults.flatten(), params.blastArgs)
    //orthogroupStatistics(groupSelfDiamondResults.collect(),makeGroupsFileResults)

    bestRepsSelfDiamondResults = bestRepsSelfDiamond(makeBestRepresentativesFastaResults, params.blastArgs)
    formatSimilarOrthogroups(bestRepsSelfDiamondResults)
}