#!/usr/bin/env nextflow
nextflow.enable.dsl=2


process createCompressedFastaDir {
  container = 'rdemko2332/orthofinder'

  input:
    path inputFasta

  output:
    path './fastas'

  script:
    template 'createCompressedFastaDir.bash'
}

process arrangeSequences {
  container = 'rdemko2332/orthofinder'

  input:
    path fastaDir

  output:
    path '*.tar.gz'

  script:
    template 'arrangeSequences.bash'
}

process orthoFinder {
  container = 'rdemko2332/orthofix'

  input:
    path tarfile

  output:
    path '*.fa', emit: fastaList
    path '*.dmnd', emit: databaseList
    tuple path('SequenceIDs.txt'), path('SpeciesIDs.txt'), emit: speciesInfo

  script:
    template 'orthoFinder.bash'
}

process diamond {
  container = 'veupathdb/diamondsimilarity'

  input:
    val pair
    path databases

  output:
    path 'Blast*.txt.gz', emit: blast
    path 'hold.txt', emit: uncompressed

  script:
    template 'diamondResidual.bash'
}


process computeGroups {
  container = 'rdemko2332/orthofix'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path blasts
    path speciesInfo
    path fastas

  output:
    path 'Results*', emit: results
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


process printSimSeqs {
  container = 'veupathdb/diamondsimilarity'

  input:
    path reformattedBlastOutput
    val pValCutoff
    val lengthCutoff
    val percentCutoff
    val adjustMatchLength

  output:
    path 'printSimSeqs.out'

  script:
    template 'printSimSeqs.bash'
}


process sortSimSeqs {
  container = 'veupathdb/diamondsimilarity'

  publishDir params.outputDir, mode: "copy"
  
  input:
    path output
        
  output:
    path 'diamondSimilarity.out'

  script:
    """
    cat $output | sort -k 1 > diamondSimilarity.out
    """
}

process renameDiamondFiles {
  container = 'rdemko2332/orthofinder'
  
  input:
    path blasts
    path speciesInfo

  output:
    path '*.txt.gz', emit: renamed

  script:
    template 'renameDiamondFiles.bash'
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

  input:
    path orthoGroupsFile
    path diamondFiles

  output:
    path 'GroupFiles/OrthoGroup*', emit: orthogroups, optional: true
    path 'GroupFiles/Singletons.dat', emit: singletons, optional: true

  script:
    template 'makeOrthogroupSpecificFiles.bash'
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

workflow residualWorkflow { 
  take:
    inputFile

  main:
    createCompressedFastaDirResults = createCompressedFastaDir(inputFile)
    arrangeSequencesResults = arrangeSequences(createCompressedFastaDirResults)
    orthoFinderResults = orthoFinder(arrangeSequencesResults)
    pairs = orthoFinderResults.fastaList.map { it -> [it,it].combinations().findAll(); }
    pairsChannel = pairs.flatten().collate(2)
    databases = orthoFinderResults.databaseList.collect()
    speciesInfo = orthoFinderResults.speciesInfo.collect()
    diamondResults = diamond(pairsChannel, databases)
    allBlastResults = diamondResults.uncompressed | collectFile()
    reformattedBlastOutputResults = reformatBlastOutput(allBlastResults, orthoFinderResults.speciesInfo)
    printSimSeqs(reformattedBlastOutputResults, params.pValCutoff, params.lengthCutoff, params.percentCutoff, params.adjustMatchLength) | sortSimSeqs
    blasts = diamondResults.blast.collect()
    renameDiamondFilesResults = renameDiamondFiles(blasts, orthoFinderResults.speciesInfo).collect()
    computeGroupsResults = computeGroups(blasts,orthoFinderResults.speciesInfo,orthoFinderResults.fastaList)
    splitOrthoGroupsFilesResults = splitOrthogroupsFile(computeGroupsResults.results)
    makeOrthogroupSpecificFilesResults = makeOrthogroupSpecificFiles(splitOrthoGroupsFilesResults.orthoGroupsFiles.flatten(), renameDiamondFilesResults)
    orthogroupCalculationsResults = orthogroupCalculations(makeOrthogroupSpecificFilesResults.orthogroups.flatten().collate(250))
    bestRepresentatives = orthogroupCalculationsResults.collectFile(name: 'bestReps.txt')
    makeBestRepresentativesFasta(bestRepresentatives, inputFile, makeOrthogroupSpecificFilesResults.singletons)
    
}