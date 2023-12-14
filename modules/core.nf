#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include {bestRepsSelfDiamond as coreBestRepsToCoreDiamond;
         bestRepsSelfDiamond as residualBestRepsToCoreAndResidualDiamond;
         bestRepsSelfDiamond as coreBestRepsToResidualDiamond;
         calculateGroupResults; collectDiamondSimilaritesPerGroup
} from './shared.nf'


/**
 * ortho finder checks for unambiguous amino acid sequences in  first few sequences of fasta.
 * ensure the first sequence in each fasta file has unambigous amino acids
 *
 * @param proteomes:  tar.gz directory of fasta files.  each named like $organismAbbrev.fasta
 * @return arrangedProteomes directory of fasta files
 *
 */
process moveUnambiguousAminoAcidSequencesFirst {
  container = 'veupathdb/orthofinder'

  input:
    path proteomes

  output:
    path 'cleanedFastas'

  script:
    template 'moveUnambiguousAminoAcidSequencesFirst.bash'
}


/**
 * orthofinder makes new primary key for protein sequences
 * this step makes new fastas and mapping files (species and sequence) and diamond index files
 * the species and sequence mapping files are published to diamondCache output directory to be used
 * by future workflows
 *
 * @param fastas:  directory of fasta files appropriate for orthofinder
 * @return orthofinderSetup directory containes mapped fastas, diamond indexes and mapping files
 * @return SpeciesIDs.txt file contains mappings from orthofinder primary keys to organism abbreviations
 * @return SequenceIDs.txt file contains mappings from orthofinder primary keys to gene/protein ids
 */
process orthoFinderSetup {
  container = 'veupathdb/orthofinder'

  publishDir "$params.outputDir/diamondCache", mode: "copy", pattern: "*.txt"

  input:
    path 'fastas'

  output:
    path 'OrthoFinder', emit: orthofinderDirectory
    path 'WorkingDirectory', emit: orthofinderWorkingDir, type: 'dir'
    path 'SpeciesIDs.txt', emit: speciesMapping
    path 'SequenceIDs.txt', emit: sequenceMapping

  script:
    template 'orthoFinder.bash'
}



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
    container = 'veupathdb/orthofinder'

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
* take diamond results from mappedCache dir if they exist OR run diamond to create (and send to cache)
*
* @param pair of integers.  There will be lots of these
* @param orthofinderWorkingDir is the direcotry with the diamond indexes and fasta files
* @param mappedBlastCache is the directory of previous blast output mapped to this run
* @return Blast*.txt is the resulting file (either from cache or new)
*/
process diamond {
  container = 'veupathdb/diamondsimilarity'

  publishDir "$params.outputDir/diamondCache", mode: "copy", pattern: "Blast*.txt"

  input:
    tuple val(target), val(queries)
    path orthofinderWorkingDir
    path mappedBlastCache
    val outputList

  output:
    path 'Blast*.txt', emit: blast

  script:
    template 'diamond.bash'
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
  container = 'veupathdb/orthofinder'

  publishDir "$params.outputDir", mode: "copy", pattern: "Results"

  input:
    path blasts
    path orthofinderWorkingDir

  output:
    path 'Results/Phylogenetic_Hierarchical_Orthogroups/N0.tsv', emit: orthologgroups
    path 'Results'

  script:
    template 'computeGroups.bash'
}

/**
* make one file containing all ortholog groups per species
* @param species
* @param speciesMapping is the NEW Species mapping from orthofinder setup step (current run)
* @param sequenceMapping is the NEW Sequence mapping from orthofinder setup step (current run)
* @param orthologgroups
* @param buildVersion
* @return orthologs
* @return singletons
*/
process splitOrthologGroupsPerSpecies {
    container = 'veupathdb/orthofinder'

    input:
    val species
    path speciesMapping
    path sequenceMapping
    path orthologgroups
    val buildVersion

    output:
    path '*.orthologs', emit: orthologs
    path "*.singletons", emit: singletons

    script:
    template 'splitOrthologGroupsPerSpecies.bash'
}

/**
* One file per orthologgroup with all diamond output for that group
* @return orthogroupblasts (sim files per group)
*/

process makeOrthogroupDiamondFiles {
  container = 'veupathdb/orthofinder'

  input:
    tuple val(target), val(queries)
    path blasts
    path orthologs

  output:
    path '*.sim', emit: orthogroupblasts

  script:
    template 'makeOrthogroupDiamondFiles.bash'
}



/**
* combine species singletons file. this will create new ortholog group IDS based on
* the last row in the orthologgroups file.  the resulting id will also include the version
*/

process makeFullSingletonsFile {
  container = 'veupathdb/orthofinder'

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
  container = 'veupathdb/orthofinder'

  input:
    path singletonsFile
    path sequenceMapping

  output:
    path 'translatedSingletons.dat'

  script:
    template 'translateSingletonsFile.bash'
}


/**
* write groups file for use in peripheral wf or to be loaded into relational db
*/
process reformatGroupsFile {
  container = 'veupathdb/orthofinder'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path groupsFile
    path translatedSingletons
    val buildVersion

  output:
    path 'reformattedGroups.txt'

  script:
    template 'reformatGroupsFile.bash'
}

/**
*  for each group, determine which sequence has the lowest average evalue
*/
process findBestRepresentatives {
  container = 'veupathdb/orthofinder'

  input:
    path groupData

  output:
    path 'best_representative.txt'

  script:
    template 'findBestRepresentatives.bash'
}


/**
*  orthofinder outputs a line "empty" which we don't care about
*/

process removeEmptyGroups {
    input:
    path singletons
    path bestReps

    output:
    path "unique_best_representative.txt"

    script:
    """
    cat $singletons >> $bestReps
    grep -v '^empty' $bestReps > unique_best_representative.txt
    """
}

/**
*  grab all best representative sequences.  use the group id as the defline
*/
process makeBestRepresentativesFasta {
  container = 'veupathdb/orthofinder'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path bestRepresentatives
    path orthofinderWorkingDir
    val isResidual

  output:
    path 'bestReps.fasta'

  script:
    template 'makeBestRepresentativesFasta.bash'
}



/**
*  In batches of ortholog groups, Read the file of bestReps (group->seq)
*  and filter the matching group.sim file.  use the singletons file
*  to exclude groups with only one sequence.
*
*/

process filterSimilaritiesByBestRepresentative {
  container = 'veupathdb/orthofinder'

  publishDir "$params.outputDir/coreSimilarityToBestReps", mode: "copy"

  input:
    path groupData
    path bestReps
    path singletons

  output:
    path '*.tsv'

  script:
    template 'filterSimilaritiesByBestRepresentative.bash'
}


process createEmptyDir {
  container = 'veupathdb/orthofinder'

  input:
    path speciesMapping

  output:
    path 'emptyDir'

  script:
    """
    mkdir emptyDir
    """
}

/**
* combine the core and residual fasta files containing best representative sequences
*
*/
process mergeCoreAndResidualBestReps {
  container = 'veupathdb/orthofinder'

  input:
    path residualBestReps
    // Avoid file name collision
    path 'coreBestReps.fasta'

  output:
    path 'bestRepsFull.fasta'

  script:
    """
    cp $residualBestReps bestRepsFull.fasta
    cat coreBestReps.fasta >> bestRepsFull.fasta
    """
}


/**
* take a list and find all possible pairwise combinations.
* organize the combinations so we can send reasonably sized chunks as individual jobs (chunkSize).
*
* Example: listToPairwiseComparisons(channel.of(1..3).collect(), 2).view();
* [1, [1, 2]]
* [2, [1, 2]]
* [3, [1, 2]]
* [1, [3]]
* [2, [3]]
* [3, [3]]
*/
def listToPairwiseComparisons(list, chunkSize) {
    return list.map { it -> [it,it].combinations().findAll(); }
        .flatMap { it }
        .groupTuple(size: chunkSize, remainder:true)

}

/**
* The speciesMapping file comes directly from orthoFinder.  This function will
* return a list from either the first or second column
*/
def speciesFileToList(speciesMapping, index) {
    return speciesMapping
        .splitText(){it.tokenize(': ')[index]}
        .map { it.replaceAll("[\n\r]", "") }
        .toList()
}



workflow coreOrResidualWorkflow {
  take:
    inputFile
    coreOrResidual

  main:
    // prepare input proteomes in format orthoFinder needs
    // finish setup by running orthoFinder in mode that creates diamond indexes
    // internal fastas and sequence/species id mappings
    proteomesForOrthofinder = moveUnambiguousAminoAcidSequencesFirst(inputFile)
    setup = orthoFinderSetup(proteomesForOrthofinder)

    // For rerunning core, we provide a direcotry of cached diamond similarities.
    // the ids in these files were generated in a previous run so need to be mapped
    // to new internal ids using previous species/sequence mapping files
    if (coreOrResidual === 'core') {
        mappedCachedBlasts = mapCachedBlasts(params.diamondSimilarityCache,
                                             params.outdatedOrganisms,
                                             setup.speciesMapping,
                                             setup.sequenceMapping);
    }
    else {
        // this will only happen when processing residuals
        mappedCachedBlasts = createEmptyDir(setup.speciesMapping).collect()
    }

    // get lists of species names and internal ids
    speciesIds = speciesFileToList(setup.speciesMapping, 0);
    speciesNames = speciesFileToList(setup.speciesMapping, 1);

    // make tuple object for processing pairwise combinations of species
    speciesPairsAsTuple = listToPairwiseComparisons(speciesIds, 25);

    // for batches of pairwise comparisons,
    // grab sim file from mapped cache if it exists, otherwise run diamond
    diamondResults = diamond(speciesPairsAsTuple,
                             setup.orthofinderWorkingDir.collect(),
                             mappedCachedBlasts.collect(),
                             params.orthoFinderDiamondOutputFields)

    // collection of all pairwise diamond results
    collectedDiamondResults = diamondResults.blast.collect()

    // run orthofinder
    orthofinderGroupResults = computeGroups(collectedDiamondResults, setup.orthofinderWorkingDir)

    //make one file per species containing all ortholog groups for that species
    speciesOrthologs = splitOrthologGroupsPerSpecies(speciesNames.flatten(),
                                                     setup.speciesMapping.collect(),
                                                     setup.sequenceMapping.collect(),
                                                     orthofinderGroupResults.orthologgroups.collect(),
                                                     params.buildVersion);

    // per species, make One file per orthologgroup with all diamond similarities for that group
    diamondSimilaritiesPerGroup = makeOrthogroupDiamondFiles(speciesPairsAsTuple,
                                                             collectedDiamondResults,
                                                             speciesOrthologs.orthologs.collect())

    // sub workflow to process diamondSimlarities for best representatives and group stats
    bestRepresentativesAndStats(setup.orthofinderWorkingDir,
                                setup.sequenceMapping,
                                orthofinderGroupResults.orthologgroups,
                                diamondSimilaritiesPerGroup,
                                speciesOrthologs.singletons,
                                coreOrResidual
    );
}


workflow bestRepresentativesAndStats {
    take:
    setupOrthofinderWorkingDir
    setupSequenceMapping
    orthofinderGroupResultsOrthologgroups
    diamondSimilaritiesPerGroup
    speciesOrthologsSingletons
    coreOrResidual

    main:

    // collect up per species diamond similaritiy files (one per group)
    allDiamondSimilaritiesPerGroup = collectDiamondSimilaritesPerGroup(diamondSimilaritiesPerGroup)

    // make a collection containing all group similarity files
    allDiamondSimilarities = allDiamondSimilaritiesPerGroup.collect()

    // make a collection of singletons files (one for each species)
    singletonFiles = speciesOrthologsSingletons.collect()

    // combine all singletons and assign a group id
    fullSingletonsFile = makeFullSingletonsFile(singletonFiles, orthofinderGroupResultsOrthologgroups, params.buildVersion).collectFile()

    // in batches, process group similarity files and determine best representative for each group
    bestRepresentatives = findBestRepresentatives(allDiamondSimilaritiesPerGroup.collate(250))

    // collect File of best representatives
    combinedBestRepresentatives = removeEmptyGroups(fullSingletonsFile, bestRepresentatives.flatten().collectFile())

    // fasta file with all seqs for best representative sequence.
    // (defline contains group id like:  OG_XXXX)
    bestRepresentativeFasta = makeBestRepresentativesFasta(combinedBestRepresentatives,
                                                           setupOrthofinderWorkingDir, false)

    // in batches of bestReps, filter the group.sim file to create a file per group with similarities where the query seq is the bestRep
    // collect up resulting files
    groupResultsOfBestRep = filterSimilaritiesByBestRepresentative(allDiamondSimilarities,
                                                                   combinedBestRepresentatives.splitText( by: 1000, file: true ),
                                                                   fullSingletonsFile).collect()

    // split bestRepresentative into chunks for parallel processing
    bestRepSubset = bestRepresentativeFasta.splitFasta(by:1000, file:true)

    if (coreOrResidual === 'core') {

        // in batches of group similarity files filted by best representative, calculate group stats from evalues (min, max, median, ...)
        calculateGroupResults(groupResultsOfBestRep.flatten().collate(250), 10, false)
            .collectFile(name: "core_stats.txt", storeDir: params.outputDir + "/groupStats" )

        // run diamond for core best representatives compared to core bestRep DB
        // this will be used to find similar ortholog groups
        bestRepsSelfDiamondResults = coreBestRepsToCoreDiamond(bestRepSubset, bestRepresentativeFasta)
            .collectFile(name: "core_best_reps_self_blast.txt", storeDir: params.outputDir );

        translatedSingletonsFile = translateSingletonsFile(fullSingletonsFile,
                                                           setupSequenceMapping)

        // Final output format of groups. Sent to peripheral workflow to identifiy which sequences are contained in which group in the core.
        reformatGroupsFile(orthofinderGroupResultsOrthologgroups,
                           translatedSingletonsFile,
                           params.buildVersion)
    }
    else { // residual

        // same as above but for residuals
        calculateGroupResults(groupResultsOfBestRep.flatten().collate(250), 10, true)
            .collectFile(name: "residual_stats.txt", storeDir: params.outputDir + "/groupStats" )

        coreAndResidualBestRepFasta = mergeCoreAndResidualBestReps(bestRepresentativeFasta,
                                                                   params.coreBestReps)

        // run diamond for residual best representatives compared to core+residual bestRep DB
        // this will be used to find similar ortholog groups
        residualBestRepsSimilarities = residualBestRepsToCoreAndResidualDiamond(bestRepSubset,
                                                                                coreAndResidualBestRepFasta).collectFile()

        // as we get new residual groups we need to compare core best reps
        // (core best reps are input to peripheral/residual workflow)
        coreBestRepsFasta = Channel.fromPath( params.coreBestReps )
        coreBestRepsFastaSubset = coreBestRepsFasta.splitFasta(by:1000, file:true)

        // run diamond for core best representatives compared to residual bestRep DB
        // this will be used to find similar ortholog groups
        coreToResidualBestRepsSimilarities = coreBestRepsToResidualDiamond(coreBestRepsFastaSubset,
                                                                           bestRepresentativeFasta).collectFile()

        // combine all bestreps self blast
        Channel.fromPath(params.coreBestRepsSelfBlast)
            .concat(residualBestRepsSimilarities)
            .concat(coreToResidualBestRepsSimilarities)
            .collectFile(name: "all_best_reps_self_blast.txt", storeDir: params.outputDir )

    }
}
