#!/usr/bin/env nextflow
nextflow.enable.dsl=2

//---------------------------------------------------------------
// Including Workflows
//---------------------------------------------------------------

include { coreWorkflow; } from './modules/core.nf'
include { peripheralWorkflow } from './modules/peripheral.nf'
include { residualWorkflow;} from './modules/residual.nf'

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
    coreEntry();
}
