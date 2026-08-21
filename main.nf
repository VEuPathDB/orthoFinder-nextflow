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
include { incrementalWorkflow;} from './modules/incremental.nf'

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
// incremental (core unchanged: reassign changed/removed/new peripheral
// organisms into existing core/residual groups, and cluster only the
// leftover unassigned sequences via the existing residual workflow --
// avoids a full peripheral+residual rebuild when core hasn't changed)
//---------------------------------------------------------------

workflow incrementalEntry {
  if(params.changedOrNewProteomes) {
    inputFile = Channel.fromPath(params.changedOrNewProteomes)
  }
  else {
    throw new Exception("Missing params.changedOrNewProteomes")
  }

  if(!params.previousFullProteome) {
    throw new Exception("Missing params.previousFullProteome")
  }
  if(!params.cachedCoreBestReps) {
    throw new Exception("Missing params.cachedCoreBestReps")
  }
  if(!params.cachedResidualBestReps) {
    throw new Exception("Missing params.cachedResidualBestReps")
  }

  incrementalWorkflow(inputFile,
                      Channel.fromPath(params.previousFullProteome),
                      Channel.fromPath(params.cachedCoreBestReps),
                      Channel.fromPath(params.cachedResidualBestReps))
}

//---------------------------------------------------------------
// DEFAULT - core
//---------------------------------------------------------------

workflow {
    coreEntry();
}
