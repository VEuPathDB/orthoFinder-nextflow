#!/usr/bin/env nextflow
nextflow.enable.dsl=2

//---------------------------------------------------------------
// Param Checking 
//---------------------------------------------------------------

if(params.inputFile) {
  inputFile = Channel.fromPath( params.inputFile )
}
else {
  throw new Exception("Missing params.inputFile")
}

//--------------------------------------------------------------------------
// Includes
//--------------------------------------------------------------------------

include { OrthoFinder } from './modules/orthoFinder.nf'

//--------------------------------------------------------------------------
// Main Workflow
//--------------------------------------------------------------------------

workflow {
  
  OrthoFinder(inputFile)

}

