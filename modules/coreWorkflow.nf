#!/usr/bin/env nextflow
nextflow.enable.dsl=2


process createCompressedFastaDir {
  container = 'rdemko2332/orthofinder'

  cache 'lenient'

  input:
    path inputFasta

  output:
    path './fastas'

  script:
    template 'createCompressedFastaDir.bash'
}

process arrangeSequences {
  container = 'rdemko2332/orthofinder'

  cache 'lenient'

  input:
    path fastaDir

  output:
    path '*.tar.gz'

  script:
    template 'arrangeSequences.bash'
}

process removeOutdatedBlasts {
  container = 'rdemko2332/orthofinder'

  cache 'lenient'

  input:
    path outdated

  output:
    path 'cleaned.txt'

  script:
    template 'removeOutdatedBlasts.bash'
}

process orthoFinder {
  container = 'rdemko2332/orthofinder'

  cache 'lenient'

  input:
    path tarfile
    path updated

  output:
    path '*.fa', emit: fastaList
    path '*.dmnd', emit: databaseList
    tuple path('SequenceIDs.txt'), path('SpeciesIDs.txt'), emit: speciesInfo

  script:
    template 'orthoFinder.bash'
}

process diamond {
  container = 'veupathdb/diamondsimilarity'

  cache 'lenient'

  input:
    val pair
    path databases
    tuple path(sequenceIDs), path(speciesIDs)

  output:
    path 'Blast*.txt.gz', emit: blast
    path 'hold.txt', emit: uncompressed

  script:
    template 'diamond.bash'
}


process renameDiamondFiles {
  container = 'rdemko2332/orthofinder'
  publishDir "$params.outputDir/newPreviousBlasts", mode: "copy", pattern: "*.txt.gz"
  
  input:
    path blasts
    path speciesInfo

  output:
    path '*.txt.gz', emit: renamed

  script:
    template 'renameDiamondFiles.bash'
}


process computeGroups {
  container = 'rdemko2332/orthofinder'

  publishDir "$params.outputDir", mode: "copy", pattern: "Results"

  input:
    path blasts
    path speciesInfo
    path fastas

  output:
    path 'Results', emit: results
    path 'SpeciesIDs.txt', emit: species
    path 'SequenceIDs.txt', emit: sequences

  script:
    template 'computeGroups.bash'
}


process reformatBlastOutput {
  container = 'rdemko2332/orthofinder'

  input:
    path blastOutput
    tuple path(sequenceIDs), path(speciesIDs)

  output:
    path 'reformattedBlast.tsv'

  script:
    template 'reformatBlastOutput.bash'
}


process splitOrthogroupsFile {
  container = 'rdemko2332/orthofinder'

  input:
    path results

  output:
    path 'OG*', emit: orthoGroupsFiles

  script:
    template 'splitOrthogroupsFile.bash'
}

process makeOrthogroupSpecificFiles {
  container = 'rdemko2332/orthofinder'

  publishDir "$params.outputDir/GroupResults", mode: "copy"

  input:
    path orthoGroupsFile
    path diamondFiles

  output:
    path 'OrthoGroup*', emit: orthogroups, optional: true
    path 'Singletons.dat', emit: singletons, optional: true

  script:
    template 'makeOrthogroupSpecificFiles.bash'
}

process orthogroupStatistics {
  container = 'rdemko2332/orthofinder'

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
  container = 'rdemko2332/orthofinder'

  input:
    path groupData

  output:
    path '*.final', emit: groupCalcs

  script:
    template 'orthogroupCalculations.bash'
}

process makeBestRepresentativesFasta {
  container = 'rdemko2332/orthofinder'

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
  container = 'rdemko2332/orthofinder'

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
    createCompressedFastaDirResults = createCompressedFastaDir(inputFile)
    arrangeSequencesResults = arrangeSequences(createCompressedFastaDirResults)
    removeOutdatedBlastsResults = removeOutdatedBlasts(params.outdated)
    orthoFinderResults = orthoFinder(arrangeSequencesResults, removeOutdatedBlastsResults)
    pairs = orthoFinderResults.fastaList.map { it -> [it,it].combinations().findAll(); }
    pairsChannel = pairs.flatten().collate(2)
    databases = orthoFinderResults.databaseList.collect()
    speciesInfo = orthoFinderResults.speciesInfo.collect()
    diamondResults = diamond(pairsChannel, databases, speciesInfo)
    allBlastResults = diamondResults.uncompressed | collectFile()
    reformattedBlastOutputResults = reformatBlastOutput(allBlastResults, orthoFinderResults.speciesInfo)
    blasts = diamondResults.blast.collect()
    renameDiamondFilesResults = renameDiamondFiles(blasts, orthoFinderResults.speciesInfo).collect()
    computeGroupsResults = computeGroups(blasts,orthoFinderResults.speciesInfo,orthoFinderResults.fastaList)
    splitOrthoGroupsFilesResults = splitOrthogroupsFile(computeGroupsResults.results)
    makeOrthogroupSpecificFilesResults = makeOrthogroupSpecificFiles(splitOrthoGroupsFilesResults.orthoGroupsFiles.flatten(), renameDiamondFilesResults)
    orthogroupStatisticsResults = orthogroupStatistics(makeOrthogroupSpecificFilesResults.orthogroups.flatten().collate(250), computeGroupsResults.results)
    orthogroupCalculationsResults = orthogroupCalculations(makeOrthogroupSpecificFilesResults.orthogroups.flatten().collate(250))
    bestRepresentatives = orthogroupCalculationsResults.collectFile(name: 'bestReps.txt')
    makeBestRepresentativesFastaResults = makeBestRepresentativesFasta(bestRepresentatives, inputFile, makeOrthogroupSpecificFilesResults.singletons)
    bestRepsSelfDiamondResults = bestRepsSelfDiamond(makeBestRepresentativesFastaResults, params.blastArgs)
    formatSimilarOrthogroups(bestRepsSelfDiamondResults)
}