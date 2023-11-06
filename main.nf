#!/usr/bin/env nextflow
nextflow.enable.dsl=2

//---------------------------------------------------------------
// Including Workflows
//---------------------------------------------------------------

include { peripheralWorkflow } from './modules/peripheral.nf'
include { listToPairwiseComparisons; coreOrResidualWorkflow as coreWorkflow } from './modules/core.nf'

//---------------------------------------------------------------
// core
//---------------------------------------------------------------

workflow coreEntry {

    if(params.proteomes) {
        inputFile = Channel.fromPath( params.proteomes )
    }
    else {
        throw new Exception("Missing params.proteomes")
    }

    if(!params.diamondSimilarityCache) {
        throw new Exception("Missing params.diamondSimilarityCache")
    }

    coreWorkflow(inputFile, "core")

}

//---------------------------------------------------------------
// peripheral
//---------------------------------------------------------------

workflow peripheralEntry {
  if(params.peripheralProteomes) {
    inputFile = Channel.fromPath(params.peripheralProteomes)
  }
  else {
    throw new Exception("Missing params.peripheralProteome")
  }

  peripheralWorkflow(inputFile)
   
}

//---------------------------------------------------------------
// DEFAULT - core
//---------------------------------------------------------------

workflow {
    //listToPairwiseComparisons(channel.of(1..10), 3).view();
    //listToPairwiseComparisons(channel.of(1..3).collect(), 2).view();
    coreEntry();
}
