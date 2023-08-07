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

process removeOutdatedBlasts {
  container = 'rdemko2332/orthofinder'

  input:
    path outdated

  output:
    path 'cleaned.txt'

  script:
    template 'removeOutdatedBlasts.bash'
}

process orthoFinder {
  container = 'rdemko2332/orthofix'

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
    path '*.txt.gz'

  script:
    template 'renameDiamondFiles.bash'
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

process astral {
  container = 'rdemko2332/orthofinderlinear'

  publishDir params.outputDir, mode: "copy"
  
  input:
    path outputDir
    path species
    path sequences
    path peripheralDir
        
  output:
    path '*'

  script:
    template 'astral.bash'
}

workflow OrthoFinder { 
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
    printSimSeqs(reformattedBlastOutputResults, params.pValCutoff, params.lengthCutoff, params.percentCutoff, params.adjustMatchLength) | sortSimSeqs
    blasts = diamondResults.blast.collect()
    renameDiamondFiles(blasts, orthoFinderResults.speciesInfo)
    computeGroupResults = computeGroups(blasts,orthoFinderResults.speciesInfo,orthoFinderResults.fastaList)
    //astral(computeGroupResults.results, computeGroupResults.species, computeGroupResults.sequences, params.peripheralDir)
}