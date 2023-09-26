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


process diamondResidual {
  container = 'veupathdb/diamondsimilarity'

  input:
    val pair
    path orthofinderWorkingDir

  output:
    path 'Blast*.txt', emit: blast

  script:
    template 'diamondResidual.bash'
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

  output:
//    path 'OrthoGroup*', emit: orthogroups, optional: true
//    path 'Singletons.dat', emit: singletons, optional: true

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


workflow coreWorkflow { 
  take:
    inputFile

  main:
    proteomesForOrthofinder = moveUnambiguousAminoAcidSequencesFirst(inputFile)

    setup = orthoFinderSetup(proteomesForOrthofinder)

    mappedCachedBlasts = mapCachedBlasts(params.diamondSimilarityCache, params.outdatedOrganisms, setup.speciesMapping, setup.sequenceMapping);

    // // get all pairwise combinations of organisms
    pairsChannel = setup.speciesMapping.splitText(){it.tokenize(':')[0]}.toList().map { it -> [it,it].combinations().findAll(); }.flatten().collate(2)

    diamondResults = diamond(pairsChannel, setup.orthofinderWorkingDir.collect(), mappedCachedBlasts.collect())

    blasts = diamondResults.blast.collect()

    computeGroupResults = computeGroups(blasts, setup.orthofinderWorkingDir)

    // TODO:  How many groups to process at a time?
//    orthologGroupSubset = computeGroupResults.orthologgroups.splitText(by: 100, file: true)

//    makeOrthogroupSpecificFilesResults = makeOrthogroupSpecificFiles(orthologGroupSubset, blasts)

//     // website stats
//     orthogroupStatisticsResults = orthogroupStatistics(makeOrthogroupSpecificFilesResults.orthogroups.flatten().collate(250), computeGroupsResults.results)

//     //TODO Rename this "best representative per group"
//     orthogroupCalculationsResults = orthogroupCalculations(makeOrthogroupSpecificFilesResults.orthogroups.flatten().collate(250))


    // Defline named by the group ID;  No mapping of sequenceIDs needed
//     makeBestRepresentativesFastaResults = makeBestRepresentativesFasta(orthogroupCalculationsResults, inputFile, makeOrthogroupSpecificFilesResults.singletons)

//     bestRepsSelfDiamondResults = bestRepsSelfDiamond(makeBestRepresentativesFastaResults, params.blastArgs)

//     formatSimilarOrthogroups(bestRepsSelfDiamondResults)

}

workflow residualWorkflow { 
  take:
    inputFile

  main:

    compressedFastaDir = createCompressedFastaDir(inputFile)
    emptyBlastDir = createEmptyBlastDir(compressedFastaDir.complete)
    emptyDir = emptyBlastDir.collect()
    proteomesForOrthofinder = moveUnambiguousAminoAcidSequencesFirst(compressedFastaDir.fastaDir)
    setup = orthoFinderSetup(proteomesForOrthofinder)
    // // get all pairwise combinations of organisms
    pairsChannel = setup.speciesMapping.splitText(){it.tokenize(':')[0]}.toList().map { it -> [it,it].combinations().findAll(); }.flatten().collate(2)
    diamondResults = diamond(pairsChannel, setup.orthofinderWorkingDir.collect(), emptyDir)
    blasts = diamondResults.blast.collect()
    computeGroupResults = computeGroups(blasts, setup.orthofinderWorkingDir)

    // splitOrthoGroupsFilesResults = splitOrthogroupsFile(computeGroupsResults.results)
    // makeOrthogroupSpecificFilesResults = makeOrthogroupSpecificFiles(splitOrthoGroupsFilesResults.orthoGroupsFiles.flatten(), renameDiamondFilesResults)
    // orthogroupStatisticsResults = orthogroupStatistics(makeOrthogroupSpecificFilesResults.orthogroups.flatten().collate(250), computeGroupsResults.results)
    // orthogroupCalculationsResults = orthogroupCalculations(makeOrthogroupSpecificFilesResults.orthogroups.flatten().collate(250))
    // makeBestRepresentativesFasta(orthogroupCalculationsResults, inputFile, makeOrthogroupSpecificFilesResults.singletons)
    // splitProteomesByGroupResults = splitProteomeByGroup(inputFile, computeGroupsResults.results)
    
}