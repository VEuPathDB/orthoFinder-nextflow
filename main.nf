#!/usr/bin/env nextflow
nextflow.enable.dsl=2

//---------------------------------------------------------------
// Including Workflows
//---------------------------------------------------------------

include { coreWorkflow; } from './modules/core.nf'
include { peripheralWorkflow } from './modules/peripheral.nf'
include { residualWorkflow;} from './modules/residual.nf'
include { postResidualWorkflow;} from './modules/postResidual.nf'
include { postProcessingWorkflow;} from './modules/postProcessing.nf'
include { updatePeripheralWorkflow } from './modules/updatePeripheral.nf'
include { updateResidualWorkflow } from './modules/updateResidual.nf'
include { postUpdateWorkflow } from './modules/postUpdate.nf'

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
// residual
//---------------------------------------------------------------

workflow residualEntry {
  residualWorkflow(params.residualFastaDir)
}

//---------------------------------------------------------------
// postResidual
//---------------------------------------------------------------

workflow postResidualEntry {
  postResidualWorkflow(Channel.fromPath(params.groupsFile))
}

//---------------------------------------------------------------
// postProcessing
//---------------------------------------------------------------

workflow postProcessingEntry {
  postProcessingWorkflow(Channel.fromPath(params.coreBestRepsFasta))
}

//---------------------------------------------------------------
// updatePeripheral
//---------------------------------------------------------------

workflow updatePeripheralEntry {
  if(params.newPeripheralProteomes) {
    inputFile = Channel.fromPath(params.newPeripheralProteomes)
  }
  else {
    throw new Exception("Missing params.newPeripheralProteomes")
  }

  updatePeripheralWorkflow(inputFile)
}

//---------------------------------------------------------------
// updateResidual
//---------------------------------------------------------------

workflow updateResidualEntry {
  updateResidualWorkflow(params.newResidualFastaDir)
}

//---------------------------------------------------------------
// postUpdate
//---------------------------------------------------------------

workflow postUpdateEntry {
  postUpdateWorkflow(Channel.fromPath(params.coreBestRepsFasta))
}

//---------------------------------------------------------------
// DEFAULT - core
//---------------------------------------------------------------

workflow {
    coreEntry();
}
