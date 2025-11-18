#!/usr/bin/env nextflow
nextflow.enable.dsl=2


include { calculateGroupStats; calculateGroupStats as calculateCoreGroupStats;
          uncompressFastas; uncompressFastas as uncompressPeripheralFastas;
	  collectDiamondSimilaritesPerGroup; splitBySize;
	  createGeneTrees; createGeneTrees as createLargeGeneTrees;
          runMash; runMash as runCoreMash;
	  splitProteomeByGroup; combineProteomes;
        } from './shared.nf'
include { residualWorkflow } from './residual.nf'


/**
 * Splits peripheral proteome into one fasta per organism. Place these into a singular directory and compress.
 * This is the input for orthofinder.
 *
 * @param inputFasta:  The fasta file containing all of the peripheral sequences
 * @return fastaDir A compressed directory of proteomes fastas
*/
process createCompressedFastaDir {
  container = 'veupathdb/orthofinder:1.8.0'

  input:
    path inputFasta
    path 'proteomes'

  output:
    path 'fastas.tar.gz', emit: fastaDir
    stdout emit: complete

  script:
    template 'createCompressedFastaDir.bash'
}


/**
 * Creates a diamond database from the core best representatives
 *
 * @param newdbfasta: An input fasta containing the core best representative sequences  
 * @return newdb.dmnd A diamond database to be used in diamond jobs
*/
process createDatabase {
  container = 'veupathdb/orthofinder:1.8.0'

  input:
    path newdbfasta

  output:
    path 'newdb.dmnd'

  script:
    template 'createDatabase.bash'
}


/**
 * Blast a peripheral proteome against the core best representative diamond database
 *
 * @param fasta: A peripheral organism proteome
 * @param database: The diamond database of core best representatives
 * @param peripheralDiamondCache: A directory of diamond output files, named by organism, from the last peripheral run
 * @param outputList: A string of output fields to tell diamond what outout we want to retriece in a tsv format
 * @return similarities The diamond output file containing pairwise similarities
 * @return fasta The peripheral organism proteome
*/
process peripheralDiamond {
  container = 'veupathdb/diamondsimilarity:1.0.0'

  publishDir "$params.outputDir/newPeripheralDiamondCache", mode: "copy", pattern: "*.out"

  input:
    path fasta
    path database
    path peripheralDiamondCache
    val outputList

  output:
    path '*.out', emit: similarities
    path fasta, emit: fasta


  script:
    template 'peripheralDiamondSimilarity.bash'
}


/**
 * Assign groups to sequences based off the lowest e-value of each sequence when blasted against all of the core best representatives
 *
 * @param diamondInput: The diamond output file from the peripheralDiamond process
 * @param param: The peripheral organism proteome
 * @return sortedGroups A tsv file. Each line contains the sequence ID and the group it has been assigned to
 * @return diamondInput The diamond output file from the peripheralDiamond process
 * @return fasta The peripheral organism proteome
*/
process assignGroups {
  container = 'veupathdb/orthofinder:1.8.0'

  input:
    path diamondInput
    path fasta
    path groupFile
        
  output:
    path 'groups.txt', emit: groups
    path diamondInput, emit: similarities
    path fasta, emit: fasta

  script:
    template 'assignGroups.bash'
}


/**
 * Creates a peripheral (non-residual) and residual fasta file. If a sequence was assigned a group (had pairwise result to a core best representative that's e-value score was below our cutoff), it is a non-residual and is sent to the peripheral fasta. If the sequence was not assigned to a group, it is sent to the residual fasta file.
 *
 * @param groups: The file containing the peripheral sequences and the groups they were assigned to
 * @param param: The peripheral organism proteome
 * @return residualFasta A fasta file containing the residual sequences (sequences that have not been assigned to a group)
 * @return peripheralFasta A fasta file containing the peripheral (non-residual) sequences
*/
process makeResidualAndPeripheralFastas {
  container = 'veupathdb/orthofinder:1.8.0'

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


/**
 * Remove the cache pairwise blast results from the last peripheral run for all peripheral organisms that have changed proteomes
 *
 * @param outdatedOrganisms: A text file, with the organism abbreviation of a peripheral organism that has an updated proteome since the last peripheral run, one per line
 * @param peripheralDiamondCache: A directory containing the diamond results from the last peripheral workflow run. One file per organism to the core best representative diamond database
 * @return cleanedCache A new directory that contains diamond results for peripheral organism that have not changed. We can retrieve their results from the cache as they have not changed
*/
process cleanPeripheralDiamondCache {
  container = 'veupathdb/orthofinder:1.8.0'

  input:
    path outdatedOrganisms
    path peripheralDiamondCache 

  output:
    path 'cleanedCache'

  script:
    template 'cleanPeripheralDiamondCache.bash'
}


/**
 * Adds the peripheral sequence ids to the groups file generated by the core nextflow workflow
 *
 * @param coreGroups: The groups file from the core nextflow workflow
 * @param peripheralGroups: The groups file containing a peripheral sequence ID and the group it has been assigned to  
 * @return GroupsFile The full groups file containing core and peripheral sequences
*/
process makeGroupsFile {
  container = 'veupathdb/orthofinder:1.8.0'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path coreGroups
    path peripheralGroups

  output:
    path 'GroupsFile.txt'

  script:
    template 'makeGroupsFile.bash'
}


/**
 * Split the core proteome by group
 *
 * @param proteome: The combined core proteome
 * @param groups: The core groups file
 * @param outdated: The outdated organism file  
 * @return fasta A fasta file per group
*/
process splitCoreProteomeByGroup {
  container = 'veupathdb/orthofinder:1.8.0'

  input:
    path proteome
    path groups
    path outdated

  output:
    path '*.fasta'

  script:
    template 'splitProteomeByGroup.bash'
}


/**
 *  Combines blast similarities. One file per core and peripheral.
 *  Core sequences between them and the best representative for the group to which they were assigned. Same for the peripherals.
 *  This will give us all of the needed similarity score to determine best representatives.
 *
 * @param peripheralGroupSimilarities: Pairwise blast results between peripheral sequences and the core sequences per group
 * @param coreGroupSimilarities: Pairwise blast results between core sequences and their share core group membets
 * @return final Pairwise blast result files per group containing all results involving core and peripheral sequences to sequences in the group which they were assigned
*/
process combinePeripheralAndCoreSimilarities {
  container = 'veupathdb/orthofinder:1.8.0'

  input:
    path peripheralGroupSimilarities
    path coreGroupSimilarities

  output:
    path 'final/*'

  script:
    template 'combinePeripheralAndCoreSimilarities.bash'
}


/**
 *  Splits blast peripheral diamond similarities by group.
 *
 * @param blastFile: Pairwise blast results between peripheral sequences and the core sequences
 * @param groupsFile: Core and periphearl groups file
 * @return final Pairwise blast result files per group containing all results involving core and peripheral sequences to sequences in the group which they were assigned
*/
process makePeripheralOrthogroupDiamondFiles {
  container = 'veupathdb/orthofinder:1.8.0'

  input:
    path blastFile
    path groupsFile

  output:
    path 'OG*.sim', emit: blastsByOrthogroup

  script:
    template 'makePeripheralOrthogroupDiamondFiles.bash'
}


process createIntraGroupBlastFile {
  container = 'veupathdb/orthofinder:1.8.0'

  publishDir "$params.outputDir/", mode: "copy"

  input:
    path blastFiles
    path translateFile
    path bestReps

  output:
    path 'intraGroupBlastFile.tsv'

  script:
    template 'createIntraGroupBlastFile.bash'
}



/**
 *  for each group, determine which sequence has the lowest average evalue
 *
 * @param groupData: All group specific pairwise blast results between peripheral and core sequences
 * @param missingGroups: A file that lists all of the groups that do not have a file present due to the group only consisting of a core singleton
 * @param groupsMapping: Core and periphearl groups file
 * @param sequenceMapping: Orthofinder internal sequence mapping from core workflow
 * @return A file that lists all of the groups best representatives
*/
process findBestRepresentatives {
  container = 'veupathdb/orthofinder:1.8.0'

  publishDir "$params.outputDir/", mode: "copy", saveAs: { filename -> "coreBestReps.txt" }

  input:
    path groupData
    path missingGroups
    path groupMapping
    path sequenceMapping

  output:
    path 'best_representative.txt'

  script:
    template 'findBestRepresentatives.bash'
}


/**
 *  grab all best representative sequences.  use the group id as the defline
 *
 * @param bestRepresentatives: A file that lists all of the groups best representatives
 * @param proteome: A combined core and peripheral proteome fasta
 * @return A fasta file of all the group best reps, with the groupID as the defline
*/
process makeCoreBestRepresentativesFasta {
  container = 'veupathdb/orthofinder:1.8.0'

  input:
    path bestRepresentatives
    path proteome

  output:
    path 'coreBestReps.fasta'

  script:
    template 'makeCoreBestRepresentativesFasta.bash'
}

/**
 * checkForMissingGroups
 *
 * @param allDiamondSimilarities: All group specific pairwise blast results
 * @param buildVersion: Current build version
 * @param groupsFile: Residual groups file
 * @return A file that lists all of the groups that do not have a file present
*/
process checkForMissingGroups {
  container = 'veupathdb/orthofinder:1.8.0'

  input:
    path allDiamondSimilarities
    val buildVersion
    path groupsFile

  output:
    path 'missingGroups.txt'

  script:
    """
    checkForMissingGroups.pl . $buildVersion $groupsFile
    """
}

/**
 * checkForMissingCoreGroups
 *
 * @param allDiamondSimilarities: All group specific pairwise blast results between peripheral and core sequences
 * @param buildVersion: Current build version
 * @param groupsFile: Core and periphearl groups file
 * @return A file that lists all of the groups that do not have a file present due to the group only consisting of a core singleton
*/
process checkForMissingCoreGroups {
  container = 'veupathdb/orthofinder:1.8.0'

  input:
    path allDiamondSimilarities
    val buildVersion
    path groupsFile

  output:
    path 'missingGroups.txt'

  script:
    """
    checkForMissingGroups.pl $allDiamondSimilarities $buildVersion $groupsFile
    """
}

workflow peripheralWorkflow { 
  take:
    peripheralDir

  main:

    // Uncompress input directory that contains a proteome fasta per organism. This is done for both the core and peripheral.
    uncompressAndMakePeripheralFastaResults = uncompressPeripheralFastas(peripheralDir)
    uncompressAndMakeCoreFastaResults = uncompressFastas(params.coreProteomes)

    peripheralProteomeDir = uncompressAndMakePeripheralFastaResults.proteomeDir.collect()

    // Create a diamond database from a fasta file of the core sequences
    database = createDatabase(uncompressAndMakeCoreFastaResults.combinedProteomesFasta)

    // Remove cached diamond results for organisms proteomes that have changed
    cleanPeripheralDiamondCacheResults = cleanPeripheralDiamondCache(params.outdatedOrganisms,
                                                                     params.peripheralDiamondCache)

    // Run Diamond (forks so we get one process per organism; )
    similarities = peripheralDiamond(uncompressAndMakePeripheralFastaResults.proteomes.flatten(),
                                     database,
				     cleanPeripheralDiamondCacheResults,
				     params.orthoFinderDiamondOutputFields)

    // Assigning Groups
    groupsAndSimilarities = assignGroups(similarities.similarities,
                                         similarities.fasta,
					 params.coreGroupsFile)

    // split out residual and peripheral per organism and then collect into residuals and peripherals fasta
    residualAndPeripheralFastas = makeResidualAndPeripheralFastas(groupsAndSimilarities.groups,
                                                                  groupsAndSimilarities.fasta)

    residualFasta = residualAndPeripheralFastas.residualFasta.collectFile(name: 'residual.fasta');
    peripheralFasta = residualAndPeripheralFastas.peripheralFasta.collectFile(name: 'peripheral.fasta');

    // Combine core and peripheral proteomes into a singular file
    combinedProteome = combineProteomes(uncompressAndMakeCoreFastaResults.combinedProteomesFasta,
                                        peripheralFasta)

    // collect up the groups
    groupAssignments = groupsAndSimilarities.groups.collectFile(name: 'groups.txt')

    // make a combined core and peripheral group file
    makeGroupsFileResults = makeGroupsFile(params.coreGroupsFile, groupAssignments)

    // Move the below two to shared and also why do we need the outdated organisms

    // make group fastas from core fastas and group assignments
    splitCoreProteomesByGroupResults = splitCoreProteomeByGroup(uncompressAndMakeCoreFastaResults.combinedProteomesFasta.collect(),
                                                                params.coreGroupsFile,
								params.outdatedOrganisms)

    // make group fastas from core and peripheral fastas and group assignments
    splitCombinedProteomesByGroupResults = splitProteomeByGroup(combinedProteome.collect(),
                                                        makeGroupsFileResults)

    // make group specific peripheral diamond results
    peripheralBlastsByGroup = makePeripheralOrthogroupDiamondFiles(similarities.similarities.collectFile(name: 'blasts.out'),
                                                                   makeGroupsFileResults.collect())

    // In one file PER GROUP, combine core + peripheral similarities
    allSimilarities = combinePeripheralAndCoreSimilarities(peripheralBlastsByGroup.collect(),
                                                           params.coreGroupSimilarities).collect();

    // Create a file to identify all groups without similarity file
    missingGroups = checkForMissingGroups(allSimilarities,
                                          params.buildVersion,
					  makeGroupsFileResults.collect()).collect()

    // Create a file to identify all core groups without similarity file
    missingCoreGroups = checkForMissingCoreGroups(params.coreGroupSimilarities,
                                                  params.buildVersion,
					          params.coreGroupsFile).collect()

    // Identify group best representatives
    bestRepresentatives = findBestRepresentatives(allSimilarities,
                                                  missingGroups,
						  makeGroupsFileResults.collect(),
						  params.coreTranslateSequenceFile);

    createIntraGroupBlastFile(allSimilarities, params.coreTranslateSequenceFile, bestRepresentatives)

    // At this point, we have best reps, core group similarites, and core and peripheral similarities. Let's use these to calculate stats. What about missing rows? Use group file.
    // Take group file, add a row for every missing sequence pair

    // Calculate core group stats
    calculateCoreGroupStats(bestRepresentatives, params.coreGroupSimilarities, makeGroupsFileResults, params.coreTranslateSequenceFile, missingCoreGroups, false).collectFile(name: "core_stats.txt", storeDir: params.outputDir + "/groupStats")

    // Calculate core and peripheral group stats
    calculateGroupStats(bestRepresentatives, allSimilarities, makeGroupsFileResults, params.coreTranslateSequenceFile, missingGroups, true).collectFile(name: "peripheral_stats.txt", storeDir: params.outputDir + "/groupStats")

    // Creating Core + Peripheral Group Fasta Channels By Size
    splitBySizeResults = splitBySize(splitCombinedProteomesByGroupResults.collect().flatten().collate(50))

    // Creating Core + Peripheral Gene Trees
    //createGeneTrees(splitBySizeResults.small)
    //createLargeGeneTrees(splitBySizeResults.large.collect().flatten())

    // Make core best representative fasta tile with group number as defline
    bestRepresentativeFasta = makeCoreBestRepresentativesFasta(bestRepresentatives,uncompressAndMakeCoreFastaResults.combinedProteomesFasta)

    // Residual Processing

    // Split residual proteome into one fasta per organism and compress. Needed input for orthofinder. Needs peripheralProteomes to be able to split sequences up by organism as deflines are inconsistent
    compressedFastaDir = createCompressedFastaDir(residualFasta, peripheralProteomeDir)

    residualWorkflow(compressedFastaDir.fastaDir, bestRepresentativeFasta, combinedProteome, makeGroupsFileResults.collect(), "residual")
}
