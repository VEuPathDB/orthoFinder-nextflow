include {listToPairwiseComparisons; makeDiamondResultsFile;
	 moveUnambiguousAminoAcidSequencesFirst; orthoFinderSetup;
	 speciesFileToList; diamond;
} from './shared.nf'


process createResidualFasta {
  container = 'veupathdb/orthofinder:1.9.2'

  publishDir "$params.outputDir/", mode: "copy"

  input:
    path residualFastas

  output:
    path 'residualFasta.fa'

  script:
    """
    touch residualFasta.fa
    for f in $residualFastas/*; do cat \$f >> residualFasta.fa; done
    echo "Done"
    """
}


/**
* Run orthofinder to compute residual groups
*
* @param blasts:  precomputed diamond similarities for all pairs
* @param orthofinderWorkingDir is the direcotry with the diamond indexes and fasta files
* @return N0.tsv is the resulting file from orthofinder
* @return Results (catch all results)
*/

process computeResidualGroups {
  container = 'veupathdb/orthofinder:1.9.2'

  publishDir "$params.outputDir/", mode: "copy"

  input:
    path blasts
    path orthofinderWorkingDir

  output:
    path 'Orthogroups.txt', emit: orthologgroups
    path 'Results', emit: results
    path 'SequenceIDs.txt'
    path 'SpeciesIDs.txt'

  script:
    template 'computeResidualGroups.bash'
}


process createEmptyDir {
  container = 'veupathdb/orthofinder:1.9.2'

  input:
    path speciesMapping

  output:
    path 'emptyDir'

  script:
    """
    mkdir emptyDir
    """
}


workflow residualWorkflow {
  take:
    residualFastaDir

  main:
    // prepare input proteomes in format orthoFinder needs
    proteomesForOrthofinder = moveUnambiguousAminoAcidSequencesFirst(residualFastaDir).collect()

    residualFasta = createResidualFasta(proteomesForOrthofinder)

    // internal fastas and sequence/species id mappings
    setup = orthoFinderSetup(proteomesForOrthofinder)

    // create empty dir as we are processing residuals
    mappedCachedBlasts = createEmptyDir(setup.speciesMapping).collect()

    // get lists of species names and internal ids
    speciesIds = speciesFileToList(setup.speciesMapping, 0);
    speciesNames = speciesFileToList(setup.speciesMapping, 1);

    // make tuple object for processing pairwise combinations of species
    speciesPairsAsTuple = listToPairwiseComparisons(speciesIds, 500);

    // for batches of pairwise comparisons,
    // grab sim file from mapped cache if it exists, otherwise run diamond
    diamondResults = diamond(speciesPairsAsTuple,
                             setup.orthofinderWorkingDir.collect(),
                             mappedCachedBlasts.collect(),
                             params.orthoFinderDiamondOutputFields)

    // collection of all pairwise diamond results
    collectedDiamondResults = diamondResults.blast.collect()

    diamondResultsFile = makeDiamondResultsFile(collectedDiamondResults)

    orthofinderGroupResults = computeResidualGroups(collectedDiamondResults, setup.orthofinderWorkingDir)
}

