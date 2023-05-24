#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process orthoFinder {
  container = 'davidemms/orthofinder:2.5.5.1'

  publishDir "$params.outputDir", mode: "copy", pattern: "*.txt"
  publishDir "$params.outputDir", mode: "copy", pattern: "*.fa"

  input:
    path tarfile

  output:
    path 'commands', emit: commandFile
    path '*.txt'
    path '*.fa'

  script:
    template 'orthoFinder.bash'
}

process filterBlastCommands {
  container = 'rdemko2332/orthofinder'

  input:
    path commandFile

  output:
    path 'command*.txt'

  script:
    template 'filterBlastCommands.bash'
}

process retrieveFilePaths {
  container = 'rdemko2332/orthofinder'

  input:
    path filteredCommand

  output:
    env dataPath, emit: datapath
    env queryPath, emit: querypath
    env outputPath, emit: outputpath

  script:
    template 'retrieveFilePaths.bash'

}

process diamond {
  container = 'veupathdb/diamondsimilarity'

  publishDir "$params.outputDir", mode: "copy", pattern: "*.gz"

  input:
    path dataFile
    path queryFile
    val outputPath

  output:
    path 'Blast*.txt.gz'
    path 'done.txt', emit: doneFile    

  script:
    template 'diamond.bash'
}

process returnBlastOutputPath {
  container = 'davidemms/orthofinder:2.5.5.1'

  input:
    path doneFile

  output:
    env  blastOutputPath

  script:
    template 'returnBlastOutputPath.bash'
}

process computeGroups {
  container = 'davidemms/orthofinder:2.5.5.1'

  input:
    path diamondResultsDir

  script:
    template 'computeGroups.bash'
}

workflow OrthoFinder {
  take:
    tarFile

  main:
    orthoFinderResults = orthoFinder(tarFile)
    filterBlastCommandsResults = filterBlastCommands(orthoFinderResults.commandFile).flatten()
    retrieveFilePathResults = retrieveFilePaths(filterBlastCommandsResults)
    diamondResults = diamond(retrieveFilePathResults.datapath, retrieveFilePathResults.querypath,retrieveFilePathResults.outputpath)
    doneFile = diamondResults.doneFile.collectFile(name: 'doneFile.txt')
    returnBlastOutputPathResults = returnBlastOutputPath(doneFile)
    computeGroups(returnBlastOutputPathResults)
    
}