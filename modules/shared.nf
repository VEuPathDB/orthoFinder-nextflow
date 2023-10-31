#!/usr/bin/env nextflow
nextflow.enable.dsl=2


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


/**
 * orthofinder makes new primary key for protein sequences
 * this step makes new fastas and mapping files (species and sequence) and diamond index files
 * the species and sequence mapping files are published to diamondCache output directory
 * @param fastas:  directory of fasta files appropriate for orthofinder
 * @return orthofinderSetup directory containes mapped fastas, diamond indexes and mapping files
 * @return SpeciesIDs.txt file contains mappings from orthofinder primary keys to organism abbreviations
 * @return SequenceIDs.txt file contains mappings from orthofinder primary keys to gene/protein ids
 */
process orthoFinderSetup {
  container = 'veupathdb/orthofinder'

  publishDir "$params.outputDir/diamondCache", mode: "copy", pattern: "*.txt"

  input:
    path 'fastas'

  output:
    path 'OrthoFinder', emit: orthofinderDirectory
    path 'WorkingDirectory', emit: orthofinderWorkingDir, type: 'dir'
    path 'SpeciesIDs.txt', emit: speciesMapping
    path 'SequenceIDs.txt', emit: sequenceMapping

  script:
    template 'orthoFinder.bash'
}
