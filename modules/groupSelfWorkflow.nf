#!/usr/bin/env nextflow
nextflow.enable.dsl=2

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
  container = 'rdemko2332/diamondsimilarity'

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

process orthogroupStatistics {
  container = 'rdemko2332/orthofinder'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path groupData
    path results

  output:
    path '*.tsv'

  script:
    template 'orthogroupStatisticsGroup.bash'
}

workflow groupSelfWorkflow { 
  take:
    inputFile

  main:

    cleanCacheResults = cleanCache(params.updateList)
    combinedProteome = combineProteomes(inputFile, params.peripheralProteome, cleanCacheResults)
    makeGroupsFileResults = makeGroupsFile(params.coreGroupsFile, params.peripheralGroupsFile)
    splitProteomesByGroupResults = splitProteomeByGroup(combinedProteome, makeGroupsFileResults, params.updateList)
    groupSelfDiamondResults = groupSelfDiamond(splitProteomesByGroupResults.collect().flatten(), params.blastArgs)
    orthogroupStatistics(groupSelfDiamondResults.collect(),makeGroupsFileResults)   
}