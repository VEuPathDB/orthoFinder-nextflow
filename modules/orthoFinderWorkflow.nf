#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { calculateGroupResults; uncompressFastas; uncompressFastas as uncompressPeripheralFastas; collectDiamondSimilaritesPerGroup} from './shared.nf'
include { coreOrResidualWorkflow  } from './core.nf'


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



// process splitOrthogroupsFile {
//   container = 'veupathdb/orthofinder'

//   input:
//     path results

//   output:
//     path 'OG*', emit: orthoGroupsFiles

//   script:
//     template 'splitOrthogroupsFile.bash'
// }


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
    path fasta, emit: fasta


  script:
    template 'peripheralDiamondSimilarity.bash'
}


process assignGroups {
  container = 'veupathdb/orthofinder'

  input:
    path diamondInput
    path fasta
        
  output:
    path 'sortedGroups.txt', emit: groups
    path diamondInput, emit: similarities
    path fasta, emit: fasta

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






// process calculatePeripheralGroupResults {
//   container = 'veupathdb/orthofinder'

//   publishDir "$params.outputDir/peripheralAndCoreGroupStats", mode: "copy"

//   input:
//     path groupResultsToBestReps
//     val evalueColumn
//     val isResidual

//   output:
//     path '*final.tsv'

//   script:
//     template 'calculateGroupResults.bash'
// }






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

    // Run Diamond (forks so we get one process per organism; )
    similarities = peripheralDiamond(uncompressAndMakePeripheralFastaResults.proteomes.flatten(), database, cleanPeripheralDiamondCacheResults, params.orthoFinderDiamondOutput)

    // Assigning Groups
    groupsAndSimilarities = assignGroups(similarities.similarities, similarities.fasta)

    // split out residual and peripheral per organism and then collect into residuals and peripherals fasta
    residualAndPeripheralFastas = makeResidualAndPeripheralFastas(groupsAndSimilarities.groups, groupsAndSimilarities.fasta)
    residualFasta = residualAndPeripheralFastas.residualFasta.collectFile(name: 'residual.fasta');
    peripheralFasta = residualAndPeripheralFastas.peripheralFasta.collectFile(name: 'peripheral.fasta');

    // collect up the groups
    groupAssignments = groupsAndSimilarities.groups.collectFile(name: 'groups.txt')

    // Calculating Core + Peripheral Group Similarity Results
    groupSimilarityResultsToBestRep = getPeripheralResultsToBestRep(groupsAndSimilarities.similarities, groupsAndSimilarities.groups)

    // in one file PER GROUP, collect up all peripheral similarities to best Rep
    peripheralSimilaritiesToBestRep = collectDiamondSimilaritesPerGroup(groupSimilarityResultsToBestRep).collect()

    // in one file PER GROUP, combine core + peripheral similarities
    allSimilaritiesToBestRep = combinePeripheralAndCoreSimilaritiesToBestReps(peripheralSimilaritiesToBestRep, params.coreSimilarityToBestReps).collect();

    // for X number of groups (100?), calculate stats on evalue
    calculateGroupResults(allSimilaritiesToBestRep.flatten().collate(100), 10, false).collectFile(name: "peripheral_stats.txt", storeDir: params.outputDir + "/groupStats" )

    // Creating Vore + Peripheral Gene Trees
    combinedProteome = combineProteomes(uncompressAndMakeCoreFastaResults.combinedProteomesFasta, peripheralFasta)


    // TODO: these 4 steps need work
  //   makeGroupsFileResults = makeGroupsFile(params.coreGroupsFile, groupAssignments)
  //   splitProteomesByGroupResults = splitProteomeByGroup(combinedProteome, makeGroupsFileResults.splitText( by: 100, file: true ), params.outdatedOrganisms)
  //   keepSeqIdsFromDeflinesResults = keepSeqIdsFromDeflines(splitProteomesByGroupResults.collect().flatten().collate(100))
  //   createGeneTrees(keepSeqIdsFromDeflinesResults.collect().flatten().collate(100))

    // Residual Processing
    compressedFastaDir = createCompressedFastaDir(residualFasta)

    coreOrResidualWorkflow(compressedFastaDir.fastaDir, "residual")
}
