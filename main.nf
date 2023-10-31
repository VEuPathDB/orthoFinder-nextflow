#!/usr/bin/env nextflow
nextflow.enable.dsl=2

//---------------------------------------------------------------
// Including Workflows
//---------------------------------------------------------------

include { coreWorkflow } from './modules/core.nf'
include { peripheralWorkflow } from './modules/orthoFinderWorkflow.nf'

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

  coreWorkflow(inputFile)

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

  if(params.proteomes) {
    inputFile = Channel.fromPath( params.proteomes )
  }
  else {
    throw new Exception("Missing params.proteomes")
  }

  coreWorkflow(inputFile)

}
