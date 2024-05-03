#!/usr/bin/env nextflow
nextflow.enable.dsl=2


def collectDiamondSimilaritesPerGroup(diamondSimilaritiesPerGroup) {
    return diamondSimilaritiesPerGroup
        .flatten()
        .collectFile() { item -> [ item.getName(), item ] }
}



process uncompressFastas {
  container = 'veupathdb/orthofinder'

  input:
    path inputDir

  output:
    path 'fastas/*.fasta', emit: proteomes
    path 'output.fasta', emit: combinedProteomesFasta

  script:
    template 'uncompressFastas.bash'
}



process calculateGroupResults {
  container = 'veupathdb/orthofinder'

  publishDir "$params.outputDir/groupStats", mode: "copy"

  input:
    path groupResultsToBestReps
    val evalueColumn
    val isResidual

  output:
    path 'groupStats*.txt'

  script:
    template 'calculateGroupResults.bash'
}


process bestRepsSelfDiamond {
  container = 'veupathdb/diamondsimilarity'

  input:
    path bestRepSubset
    path bestRepsFasta

  output:
    path 'bestReps.out'

  script:
    template 'bestRepsSelfDiamond.bash'
}


/**
 * Create a gene tree per group
 *
 * @param fasta: A group fasta file from the keepSeqIdsFromDeflines process  
 * @return tree Output group tree file
*/
process createGeneTrees {
  container = 'veupathdb/orthofinder'

  publishDir "$params.outputDir/geneTrees", mode: "copy"

  input:
    path fasta

  output:
    path '*.tree', optional: true

  script:
    template 'createGeneTrees.bash'
}