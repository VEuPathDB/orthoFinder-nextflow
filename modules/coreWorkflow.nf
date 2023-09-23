#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process moveUnambiguousAminoAcidSequencesFirst {
  container = 'jbrestel/orthofinder'

  input:
    path proteomes

  output:
    path 'arrangedProteomes'

  script:
    template 'moveUnambiguousAminoAcidSequencesFirst.bash'
}

process removeOutdatedBlasts {
  container = 'jbrestel/orthofinder'

  input:
    path outdatedOrganisms
    path previousBlastDir

  output:
    stdout

  script:
    template 'removeOutdatedBlasts.bash'
}

process orthoFinderSetup {
  container = 'jbrestel/orthofinder'

  publishDir "$params.outputDir/diamondCache", mode: "copy", pattern: "*.txt"

  input:
    path fastas

  output:
    path 'orthofinderSetup', emit: orthofinderDirectory
    path 'SpeciesIDs.txt', emit: speciesMapping
    path 'SequenceIDs.txt', emit: sequenceMapping

  script:
    template 'orthoFinder.bash'
}

process diamond {
  container = 'veupathdb/diamondsimilarity'

  publishDir "$params.outputDir/diamondCache", mode: "copy", pattern: "Blast*.txt"

    //cache 'lenient'

  input:
    val pair
    path orthofinderSetup
//    path previousBlastDir

  output:
    path 'Blast*.txt', emit: blast

  script:
    template 'diamond.bash'
}


process outdatedOrganisms {
    container = 'jbrestel/orthofinder'

    input:
    path previousDiamondCacheDirectory
    path outdatedOrganisms
    path speciesMapping
    path sequenceMapping

    output:
    path 'full_outdated.txt'

    script:
    template 'outdatedOrganisms.bash'

}


process renameDiamondFiles {
  container = 'jbrestel/orthofinder'
  publishDir "$params.outputDir/newPreviousBlasts", mode: "copy", pattern: "*.txt.gz"
  
  input:
    path blasts
    path speciesInfo

  output:
    path '*.txt.gz', emit: renamed

  script:
    template 'renameDiamondFiles.bash'
}


process computeGroups {
  container = 'jbrestel/orthofinder'

  publishDir "$params.outputDir", mode: "copy", pattern: "Results"

  input:
    path blasts
    path orthofinderSetup

  output:
    path 'Results', emit: results
    path 'SpeciesIDs.txt', emit: species
    path 'SequenceIDs.txt', emit: sequences

  script:
    template 'computeGroups.bash'
}


process reformatBlastOutput {
  container = 'jbrestel/orthofinder'

  input:
    path blastOutput
    tuple path(sequenceIDs), path(speciesIDs)

  output:
    path 'reformattedBlast.tsv'

  script:
    template 'reformatBlastOutput.bash'
}


process splitOrthogroupsFile {
  container = 'jbrestel/orthofinder'

  input:
    path results

  output:
    path 'OG*', emit: orthoGroupsFiles

  script:
    template 'splitOrthogroupsFile.bash'
}

process makeOrthogroupSpecificFiles {
  container = 'jbrestel/orthofinder'

  publishDir "$params.outputDir/GroupResults", mode: "copy"

  input:
    path orthoGroupsFile
    path diamondFiles

  output:
    path 'OrthoGroup*', emit: orthogroups, optional: true
    path 'Singletons.dat', emit: singletons, optional: true

  script:
    template 'makeOrthogroupSpecificFiles.bash'
}

process orthogroupStatistics {
  container = 'jbrestel/orthofinder'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path groupData
    path results

  output:
    path '*.tsv', emit: groupStats

  script:
    template 'orthogroupStatistics.bash'
}

process orthogroupCalculations {
  container = 'jbrestel/orthofinder'

  input:
    path groupData

  output:
    path '*.final', emit: groupCalcs

  script:
    template 'orthogroupCalculations.bash'
}

process makeBestRepresentativesFasta {
  container = 'jbrestel/orthofinder'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path bestReps
    path fasta
    path singletons

  output:
    path 'bestReps.fasta'

  script:
    template 'makeBestRepresentativesFasta.bash'
}

process bestRepsSelfDiamond {
  container = 'veupathdb/diamondsimilarity'

  input:
    path bestRepsFasta
    val blastArgs

  output:
    path '*.out'

  script:
    template 'bestRepsSelfDiamond.bash'
}

process formatSimilarOrthogroups {
  container = 'jbrestel/orthofinder'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path bestRepsBlast

  output:
    path 'similarOrthogroups.txt'

  script:
    template 'formatSimilarOrthogroups.bash'
}


workflow coreWorkflow { 
  take:
    inputFile

  main:
    proteomesForOrthofinder = moveUnambiguousAminoAcidSequencesFirst(inputFile)


    // removeOutdatedBlastsResults = removeOutdatedBlasts(params.outdated, params.previousBlastDir)

    // TODO:  make mappedCache dir and remove outdated

    setup = orthoFinderSetup(proteomesForOrthofinder)

    outdatedOrgs = outdatedOrganisms(params.diamondSimilarityCache, params.outdatedOrganisms, setup.speciesMapping, setup.sequenceMapping);

    pairs = setup.speciesMapping.splitText(){it.tokenize(':')[0]}.toList().map { it -> [it,it].combinations().findAll(); }
    pairsChannel = pairs.flatten().collate(2)

// TODO:  only do this if we don't have in cache
    diamondResults = diamond(pairsChannel, setup.orthofinderDirectory.collect())

     blasts = diamondResults.blast.collect()





     computeGroupsResults = computeGroups(blasts, setup.orthofinderDirectory)


//     // replace splitorthologgrupsfileresults with:
//     //Channel
//     //.fromPath('/some/path/*.txt')
//     //.splitText( by: 10

    //     splitOrthoGroupsFilesResults = splitOrthogroupsFile(computeGroupsResults.results)


// //  TODO:  Stopping here
//     makeOrthogroupSpecificFilesResults = makeOrthogroupSpecificFiles(splitOrthoGroupsFilesResults.orthoGroupsFiles.flatten(), renameDiamondFilesResults)


//     // website stats
//     orthogroupStatisticsResults = orthogroupStatistics(makeOrthogroupSpecificFilesResults.orthogroups.flatten().collate(250), computeGroupsResults.results)

//     //best representative per group
//     orthogroupCalculationsResults = orthogroupCalculations(makeOrthogroupSpecificFilesResults.orthogroups.flatten().collate(250))

//     makeBestRepresentativesFastaResults = makeBestRepresentativesFasta(orthogroupCalculationsResults, inputFile, makeOrthogroupSpecificFilesResults.singletons)
//     bestRepsSelfDiamondResults = bestRepsSelfDiamond(makeBestRepresentativesFastaResults, params.blastArgs)
//     formatSimilarOrthogroups(bestRepsSelfDiamondResults)

}
