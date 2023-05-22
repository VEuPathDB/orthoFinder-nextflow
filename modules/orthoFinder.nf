#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process orthoFinder {
  container = 'davidemms/orthofinder:2.5.4'

  publishDir params.outputDir, mode: "copy"

  input:
    path tarfile

  output:
    path 'results/*', emit: output_file

  script:
    template 'orthoFinder.bash'
}

workflow OrthoFinder {
  take:
    tarFile

  main:
    orthoFinder(tarFile) 
}