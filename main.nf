#!/usr/bin/env nextflow
nextflow.enable.dsl=2

//---------------------------------------------------------------
// Including Workflows
//---------------------------------------------------------------

include { coreWorkflow } from './modules/coreWorkflow.nf'
include { residualWorkflow } from './modules/residualWorkflow.nf'

//---------------------------------------------------------------
// core
//---------------------------------------------------------------

workflow core {

  if(params.inputFile) {
    inputFile = Channel.fromPath( params.inputFile )
  }
  else {
    throw new Exception("Missing params.inputFile")
  }

  coreWorkflow(inputFile)

}

//---------------------------------------------------------------
// residual
//---------------------------------------------------------------

workflow residual {

  if(params.inputFile) {
    inputFile = Channel.fromPath( params.inputFile )
  }
  else {
    throw new Exception("Missing params.inputFile")
  }

  residualWorkflow(inputFile)
   
}

//---------------------------------------------------------------
// DEFAULT - core
//---------------------------------------------------------------

workflow {

  if(params.inputFile) {
    inputFile = Channel.fromPath( params.inputFile )
  }
  else {
    throw new Exception("Missing params.inputFile")
  }

  coreWorkflow(inputFile)

}