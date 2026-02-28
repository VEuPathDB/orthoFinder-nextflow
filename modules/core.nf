#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include {bestRepsSelfDiamond as coreBestRepsToCoreDiamond;
         bestRepsSelfDiamond as residualBestRepsToCoreAndResidualDiamond;
         bestRepsSelfDiamond as coreBestRepsToResidualDiamond;
         collectDiamondSimilaritesPerGroup;
	 createGeneTrees; listToPairwiseComparisons;
	 moveUnambiguousAminoAcidSequencesFirst; orthoFinderSetup;
	 speciesFileToList; diamond;
	 makeDiamondResultsFile; splitOrthologGroupsPerSpecies;
} from './shared.nf'


/**
 * organisms which are being updated by this run are indicated in an outdated organisms file
 *  this step does a further check to ensure the sequence mapping file is identical;  if not it will discard the cache version
 * (this step allows us to simplify the mapping from cache by allowing us to only map species/organisms.)
 * This step will loop through the Blast*.txt and change the file name and first 2 columns based on species id mapping
 *
 * @param previousDiamondCacheDirectory is set in the nextflow config. it contains Blast files and Species/Sequence Mappings
 * @param outdatedOrganisms file contains on organism id per line and is used when we get an updated annotation for a core proteome
 * @param speciesMapping is the NEW Species mapping from orthofinder setup step (current run)
 * @param sequenceMapping is the NEW Sequence mapping from orthofinder setup step (current run)
 * @return outputDir contains a directory of Blast*.txt files with mapped ids
 */
process mapCachedBlasts {
    container = 'veupathdb/orthofinder:1.9.3'

    input:
    path previousDiamondCacheDirectory
    path outdatedOrganisms
    path speciesMapping
    path sequenceMapping

    output:
    path 'mappedCacheDir'

    script:
    template 'mapCachedBlasts.bash'
}


/**
* Run orthofinder to compute groups
*
* @param blasts:  precomputed diamond similarities for all pairs
* @param orthofinderWorkingDir is the direcotry with the diamond indexes and fasta files
* @return N0.tsv is the resulting file from orthofinder
* @return Results (catch all results)
*/

process computeGroups {
  container = 'veupathdb/orthofinder:1.9.3'

  input:
    path blasts
    path orthofinderWorkingDir

  output:
    path 'Results/Phylogenetic_Hierarchical_Orthogroups/N0.tsv', emit: orthologgroups
    path 'Results', emit: results

  script:
    template 'computeGroups.bash'
}


/**
* combine species singletons file. this will create new ortholog group IDS based on
* the last row in the orthologgroups file.  the resulting id will also include the version
*/
process makeFullSingletonsFile {
  container = 'veupathdb/orthofinder:1.9.3'

  input:
    path singletonFiles
    path orthogroups
    val buildVersion

  output:
    path 'singletonsFull.dat'

  script:
    template 'makeFullSingletonsFile.bash'
}


/**
* write singleton files with original seq ids in place of internal ids
*/
process translateSingletonsFile {
  container = 'veupathdb/orthofinder:1.9.3'

  input:
    path singletonsFile
    path sequenceMapping

  output:
    path 'translatedSingletons.dat'

  script:
    template 'translateSingletonsFile.bash'
}


/**
* One file per orthologgroup with all diamond output for that group
* @return orthogroupblasts (sim files per group)
*/
process makeCoreOrthogroupDiamondFile {
  container = 'veupathdb/orthofinder:1.9.3'

  publishDir "$params.outputDir/groupDiamondResults", mode: "copy"

  input:
    path blastFile
    path orthologs

  output:
    path 'OG*.sim', emit: blastsByOrthogroup

  script:
    template 'makeOrthogroupDiamondFile.bash'
}


/**
* write groups file for use in peripheral wf or to be loaded into relational db
*/
process reformatGroupsFile {
  container = 'veupathdb/orthofinder:1.9.3'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path groupsFile
    path translatedSingletons
    val buildVersion
    val coreOrResidual

  output:
    path 'reformattedGroups.txt'
    path 'buildVersion.txt'

  script:
    template 'reformatGroupsFile.bash'
}


workflow coreWorkflow {
  take:
    inputFile
    coreOrResidual

  main:
    // prepare input proteomes in format orthoFinder needs
    proteomesForOrthofinder = moveUnambiguousAminoAcidSequencesFirst(inputFile).collect()

    // internal fastas and sequence/species id mappings
    setup = orthoFinderSetup(proteomesForOrthofinder)

    // For rerunning core, we provide a directory of cached diamond similarities.
    // the ids in these files were generated in a previous run so need to be mapped
    // to new internal ids using previous species/sequence mapping files
    mappedCachedBlasts = mapCachedBlasts(params.diamondSimilarityCache,
                                         params.outdatedOrganisms,
                                         setup.speciesMapping,
                                         setup.sequenceMapping);

    // get lists of species names and internal ids
    speciesIds = speciesFileToList(setup.speciesMapping, 0);
    speciesNames = speciesFileToList(setup.speciesMapping, 1);

    // make tuple object for processing pairwise combinations of species
    speciesPairsAsTuple = listToPairwiseComparisons(speciesIds, 250);

    // for batches of pairwise comparisons, grab sim file from mapped cache if it exists, otherwise run diamond
    diamondResults = diamond(speciesPairsAsTuple,
                             setup.orthofinderWorkingDir.collect(),
                             mappedCachedBlasts.collect(),
                             params.orthoFinderDiamondOutputFields)

    // collection of all pairwise diamond results
    collectedDiamondResults = diamondResults.blast.collect()

    diamondResultsFile = makeDiamondResultsFile(collectedDiamondResults)

    // run orthofinder
    orthofinderGroupResults = computeGroups(collectedDiamondResults, setup.orthofinderWorkingDir)
    
    //make one file per species containing all ortholog groups for that species
    speciesOrthologs = splitOrthologGroupsPerSpecies(speciesNames.flatten(),
                                                     setup.speciesMapping.collect(),
                                                     setup.sequenceMapping.collect(),
                                                     orthofinderGroupResults.orthologgroups.collect(),
                                                     params.buildVersion,
						     "na",
						     coreOrResidual);

    // per species, make One file all diamond similarities for that group
    diamondSimilaritiesPerGroup = makeCoreOrthogroupDiamondFile(diamondResultsFile.collect(),
                                                            speciesOrthologs.orthologs.collectFile(name: 'orthologs.txt'))
							     
    allDiamondSimilaritiesPerGroup = diamondSimilaritiesPerGroup.blastsByOrthogroup.flatten()

    // make a collection of singletons files (one for each species)
    singletonFiles = speciesOrthologs.singletons.collect()

    singletonsFull = makeFullSingletonsFile(singletonFiles, orthofinderGroupResults.orthologgroups, params.buildVersion).collectFile()

    translatedSingletonsFile = translateSingletonsFile(singletonsFull,setup.sequenceMapping)

    reformatGroupsFile(orthofinderGroupResults.orthologgroups,
                       translatedSingletonsFile,
                       params.buildVersion,
                       coreOrResidual)
}
