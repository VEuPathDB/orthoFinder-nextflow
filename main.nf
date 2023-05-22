#!/usr/bin/env nextflow
nextflow.enable.dsl=2

//---------------------------------------------------------------
// Param Checking 
//---------------------------------------------------------------

if(params.tarFile) {
  tarFile = Channel.fromPath( params.tarFile )
}
else {
  throw new Exception("Missing params.tarFile")
}

//--------------------------------------------------------------------------
// Includes
//--------------------------------------------------------------------------

include { OrthoFinder } from './modules/orthoFinder.nf'

//--------------------------------------------------------------------------
// Main Workflow
//--------------------------------------------------------------------------

workflow {
  
  OrthoFinder(tarFile)

}

