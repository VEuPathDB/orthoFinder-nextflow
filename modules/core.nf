#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { calculateGroupResults; collectDiamondSimilaritesPerGroup} from './shared.nf'


/**
 * ortho finder looks for unambiguous amino acid sequences first sequences of fasta
 * ensure the first sequence in each fasta file has unambigous amino acids
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
 * the species and sequence mapping files are published to diamondCache output directory
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
 * organisms which are being updated by this run are set in a file in the nextflow config
 *  this step does a further check to ensure the sequence mapping file is identical;  if not it will add to the cache
 * (this step allows us to simplify the mapping from cache by allowing us to only map species/organisms.)
 * This step will loop through the Blast*.txt and change the file name and first 2 columns based on species id mapping
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
* will either take diamond results from mappedCache dir OR run diamond
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
* TODO fill in below:  one file containing all ortholog groups per species
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


process makeFullSingletonsFile {
  container = 'veupathdb/orthofinder'

  input:
    path singletonFiles

  output:
    path 'singletonsFull.dat'

  script:
    template 'makeFullSingletonsFile.bash'
}


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


process findBestRepresentatives {
  container = 'veupathdb/orthofinder'

  input:
    path groupData

  output:
    path 'best_representative.txt', emit: groupCalcs

  script:
    template 'findBestRepresentatives.bash'
}

process removeEmptyGroups {
    input:
    path f

    output:
    path "unique_${f}"

    script:
    """
    grep -v '^empty' $f> unique_${f}
    """
}


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


process retrieveResultsToBestRepresentative {
  container = 'veupathdb/orthofinder'

  publishDir "$params.outputDir/coreSimilarityToBestReps", mode: "copy"

  input:
    path groupData
    path bestReps
    path singletons

  output:
    path '*.tsv'

  script:
    template 'retrieveResultsToBestRepresentative.bash'
}




process bestRepsSelfDiamond {
  container = 'veupathdb/diamondsimilarity'

  input:
    path bestRepSubset
    path bestRepsFasta
    val blastArgs

  output:
    path 'bestReps.out'

  script:
    template 'bestRepsSelfDiamond.bash'
}


// process bestRepsSelfDiamondTwo {
//   container = 'veupathdb/diamondsimilarity'

//   input:
//     path bestRepSubset
//     path bestRepsFasta
//     val blastArgs

//   output:
//     path 'bestReps.out'

//   script:
//     template 'bestRepsSelfDiamond.bash'
// }

process formatSimilarOrthogroups {
  container = 'veupathdb/orthofinder'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path bestRepsBlast

  output:
    path 'similarOrthogroups.txt'

  script:
    template 'formatSimilarOrthogroups.bash'
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
    touch bestRepsFull.fasta
    cat $residualBestReps >> bestRepsFull.fasta
    cat coreBestReps.fasta >> bestRepsFull.fasta
    """
}


def listToPairwiseComparisons(list, chunkSize) {
    return list.map { it -> [it,it].combinations().findAll(); }
        .flatMap { it }
        .groupTuple(size: chunkSize, remainder:true)

}


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
    proteomesForOrthofinder = moveUnambiguousAminoAcidSequencesFirst(inputFile)
    setup = orthoFinderSetup(proteomesForOrthofinder)

    if (coreOrResidual === 'core') {
            mappedCachedBlasts = mapCachedBlasts(params.diamondSimilarityCache, params.outdatedOrganisms, setup.speciesMapping, setup.sequenceMapping);
    }
    else {
        // this will only happen when processing residuals
        mappedCachedBlasts = createEmptyDir(setup.speciesMapping).collect()
    }

    speciesIds = speciesFileToList(setup.speciesMapping, 0);
    speciesNames = speciesFileToList(setup.speciesMapping, 1);

    // process X number pairs at a time
    speciesPairsAsTuple = listToPairwiseComparisons(speciesIds, 100);

    diamondResults = diamond(speciesPairsAsTuple, setup.orthofinderWorkingDir.collect(), mappedCachedBlasts.collect(), params.orthoFinderDiamondOutput)
    collectedDiamondResults = diamondResults.blast.collect()
    orthofinderGroupResults = computeGroups(collectedDiamondResults, setup.orthofinderWorkingDir)

    speciesOrthologs = splitOrthologGroupsPerSpecies(speciesNames.flatten(), setup.speciesMapping.collect(), setup.sequenceMapping.collect(), orthofinderGroupResults.orthologgroups.collect(), params.buildVersion);

    diamondSimilaritiesPerGroup = makeOrthogroupDiamondFiles(speciesPairsAsTuple, collectedDiamondResults, speciesOrthologs.orthologs.collect())

    allDiamondSimilaritiesPerGroup = collectDiamondSimilaritesPerGroup(diamondSimilaritiesPerGroup)

    allDiamondSimilarities = allDiamondSimilaritiesPerGroup.collect()
    singletonFiles = speciesOrthologs.singletons.collect()

    fullSingletonsFile = makeFullSingletonsFile(singletonFiles)

    bestRepresentatives = findBestRepresentatives(allDiamondSimilaritiesPerGroup.collate(250))

    combinedBestRepresentatives = removeEmptyGroups(fullSingletonsFile.concat(bestRepresentatives).flatten().collectFile(name: "combined_best_representative.txt"))

    bestRepresentativeFasta = makeBestRepresentativesFasta(combinedBestRepresentatives, setup.orthofinderWorkingDir, false)

    groupResultsOfBestRep = retrieveResultsToBestRepresentative(allDiamondSimilarities, combinedBestRepresentatives.splitText( by: 1000, file: true ), fullSingletonsFile).collect()

    bestRepSubset = bestRepresentativeFasta.splitFasta(by:1000, file:true)

    if (coreOrResidual === 'core') {
        calculateGroupResults(groupResultsOfBestRep.flatten().collate(250), 10, false).collectFile(name: "core_stats.txt", storeDir: params.outputDir + "/groupStats" )
        bestRepsSelfDiamondResults = bestRepsSelfDiamond(bestRepSubset, bestRepresentativeFasta, params.bestRepDiamondOutput)

        formatSimilarOrthogroups(bestRepsSelfDiamondResults.collectFile())
        translatedSingletonsFile = translateSingletonsFile(fullSingletonsFile, setup.sequenceMapping)
        reformatGroupsFile(orthofinderGroupResults.orthologgroups, translatedSingletonsFile, params.buildVersion)
    }
    else { // residual

         calculateGroupResults(groupResultsOfBestRep.flatten().collate(250), 10, true).collectFile(name: "residual_stats.txt", storeDir: params.outputDir + "/groupStats" )
         coreAndResidualBestRepFasta = mergeCoreAndResidualBestReps(bestRepresentativeFasta, params.coreBestReps)
         bestRepsSelfDiamondResults = bestRepsSelfDiamond(bestRepSubset, coreAndResidualBestRepFasta, params.bestRepDiamondOutput)

        // TODO: below are unreviewd
        // coreBestRepsChannel = Channel.fromPath( params.coreBestReps )
        // coreBestRepSubset = coreBestRepsChannel.splitFasta(by:1000, file:true)

        // // Core to residuals only
        // coreToResidualBestRepsSelfDiamondResults = bestRepsSelfDiamondTwo(coreBestRepSubset, bestRepresentativeFasta.collect(), params.peripheralDiamondOutput)

        // // Collect orthogroup similarity results
        // allResidualBestRepsSelfDiamondResults = residualBestRepsSelfDiamondResults.collectFile()
        // allCoreToResidualBestRepsSelfDiamondResults = coreToResidualBestRepsSelfDiamondResults.collectFile()

        // // Format group similairity results
        // formatSimilarOrthogroupsResults = formatSimilarOrthogroups(allResidualBestRepsSelfDiamondResults.concat(allCoreToResidualBestRepsSelfDiamondResults))

        // // Combine residual vs core and residual, core vs residual and cached core vs core to get final results
        // combineSimilarOrthogroups(formatSimilarOrthogroupsResults.collectFile(), params.coreSimilarOrthogroups)
    }
}
