#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process combineProteomes {
  container = 'rdemko2332/orthofinder'

  input:
    path coreProteome
    path peripheralProteome    

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

  output:
    path '*.fasta'

  script:
    template 'splitProteomeByGroup.bash'
}

workflow groupSelfWorkflow { 
  take:
    inputFile

  main:

    combinedProteome = combineProteomes(inputFile, params.peripheralProteome)
    makeGroupsFileResults = makeGroupsFile(params.coreGroupsFile, params.peripheralGroupsFile)
    splitProteomesByGroupResults = splitProteomeByGroup(combinedProteome, makeGroupsFileResults)
    
}