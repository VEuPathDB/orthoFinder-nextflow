#!/usr/bin/env nextflow
nextflow.enable.dsl=2

//---------------------------------------------------------------
// Including Workflows
//---------------------------------------------------------------

include { peripheralWorkflow } from './modules/orthoFinderWorkflow.nf'
include { coreOrResidualWorkflow as coreWorkflow } from './core.nf'

//---------------------------------------------------------------
// core
//---------------------------------------------------------------

workflow core {

    if(params.proteomes) {
        inputFile = Channel.fromPath( params.proteomes )
    }
    else {
        throw new Exception("Missing params.proteomes")
    }

    if(!params.diamondSimilarityCache) {
        throw new Exception("Missing params.diamondSimilarityCache")
    }

    coreOrResidualWorkflow(inputFile, "core")

}

//---------------------------------------------------------------
// peripheral
//---------------------------------------------------------------

workflow peripheral {
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
    core();
}
