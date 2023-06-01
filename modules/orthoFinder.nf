#!/usr/bin/env nextflow
nextflow.enable.dsl=2


process createCompressedFastaDir {
  container = 'rdemko2332/orthofinder'

  input:
    path inputFasta

  output:
    path '*.tar.gz'

  script:
    template 'createCompressedFastaDir.bash'
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

  script:
    template 'diamond.bash'
}


process computeGroups {
  container = 'rdemko2332/orthofix'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path blasts
    path speciesInfo
    path fastas

  output:
    path '*'

  script:
    template 'computeGroups.bash'
}


workflow OrthoFinder { 
  take:
    inputFile

  main:
    createCompressedFastaDirResults = createCompressedFastaDir(inputFile)
    orthoFinderResults = orthoFinder(createCompressedFastaDirResults)
    pairs = orthoFinderResults.fastaList.map { it -> [it,it].combinations().findAll(); }
    pairsChannel = pairs.flatten().collate(2)
    databases = orthoFinderResults.databaseList.collect()
    diamondResults = diamond(pairsChannel, databases)
    blasts = diamondResults.blast.collect()
    computeGroups(blasts,orthoFinderResults.speciesInfo,orthoFinderResults.fastaList)
}