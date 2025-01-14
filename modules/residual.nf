include {bestRepsSelfDiamond; combineProteomes;
         calculateGroupResults; collectDiamondSimilaritesPerGroup;
	 createGeneTrees; listToPairwiseComparisons;
	 moveUnambiguousAminoAcidSequencesFirst; orthoFinderSetup;
	 speciesFileToList; diamond;
	 makeDiamondResultsFile; publishOFResults;
	 splitOrthologGroupsPerSpecies; makeOrthogroupDiamondFile;
	 runMash; splitProteomeByGroup;
} from './shared.nf'


/**
* Run orthofinder to compute residual groups
*
* @param blasts:  precomputed diamond similarities for all pairs
* @param orthofinderWorkingDir is the direcotry with the diamond indexes and fasta files
* @return N0.tsv is the resulting file from orthofinder
* @return Results (catch all results)
*/

process computeResidualGroups {
  container = 'veupathdb/orthofinder'

  input:
    path blasts
    path orthofinderWorkingDir

  output:
    path 'Results/Orthogroups/Orthogroups.txt', emit: orthologgroups
    path 'Results', emit: results

  script:
    template 'computeResidualGroups.bash'
}


/**
* combine species residual singletons file.
*/
process makeFullResidualSingletonsFile {
  container = 'veupathdb/orthofinder'

  input:
    path singletonFiles
    val buildVersion

  output:
    path 'singletonsFull.dat'

  script:
    template 'makeFullResidualSingletonsFile.bash'
}



process reformatResidualGroupsFile {
  container = 'veupathdb/orthofinder'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path groupsFile
    val buildVersion

  output:
    path 'reformattedGroups.txt'

  script:
    template 'reformatResidualGroupsFile.bash'
}


/**
*  for each group, determine which residual sequence has the lowest average evalue
*/
process findResidualBestRepresentatives {
  container = 'veupathdb/orthofinder'

  input:
    path groupData
    path groupMapping
    path sequenceMapping

  output:
    path 'best_representative.txt'

  script:
    template 'findResidualBestRepresentatives.bash'
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
    touch allReps.txt
    cat $bestReps >> allReps.txt
    cat $singletons >> allReps.txt
    grep -v '^empty' allReps.txt > noEmpty.txt
    sort -k 1 noEmpty.txt | uniq > unique_best_representative.txt
    """
}


/**
*  grab all best representative sequences.  use the group id as the defline
*/
process makeResidualBestRepresentativesFasta {
  container = 'veupathdb/orthofinder'

  input:
    path bestRepresentatives
    path orthofinderWorkingDir

  output:
    path 'bestReps.fasta'

  script:
    template 'makeResidualBestRepresentativesFasta.bash'
}


/**
*  Translate best rep file to hold actual sequenceIds, not OF internal ids
*/
process translateBestRepsFile {
  container = 'veupathdb/orthofinder'

  publishDir "$params.outputDir/", mode: "copy", saveAs: { filename -> "residualBestReps.txt" }

  input:
    path sequenceMapping
    path bestReps
    val isResidual

  output:
    path 'bestReps.txt'

  script:
    template 'translateBestRepsFile.bash'
}


/**
*  In batches of residual ortholog groups, Read the file of bestReps (group->seq)
*  and filter the matching group.sim file.  use the singletons file
*  to exclude groups with only one sequence.
*
*/
process filterResidualSimilaritiesByBestRepresentative {
  container = 'veupathdb/orthofinder'

  input:
    path allSimilarities
    path bestReps
    path singletons

  output:
    path 'bestRep.tsv'

  script:
    template 'filterResidualSimilaritiesByBestRepresentative.bash'
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

  publishDir "$params.outputDir/", mode: "copy"

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
* combine the core and residual best rep similar groups files
*
*/
process mergeCoreAndResidualSimilarGroups {
  container = 'veupathdb/orthofinder'

  publishDir "$params.outputDir/", mode: "copy"

  input:
    // Avoid file name collision
    path 'coreSimilarGroups'
    path 'coreAndResidualSimilarGroups'
    path 'residualSimilarGroups'

  output:
    path 'all_best_reps_self_blast.txt'

  script:
    """
    cp coreSimilarGroups all_best_reps_self_blast.txt
    cat coreAndResidualSimilarGroups >> all_best_reps_self_blast.txt
    cat residualSimilarGroups >> all_best_reps_self_blast.txt
    """
}



process createResidualFasta {
  container = 'veupathdb/orthofinder'

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



process calculateResidualGroupResults {
  container = 'veupathdb/orthofinder'

  publishDir "$params.outputDir/groupStats", mode: "copy"

  input:
    path bestRepsTsv
    val evalueColumn

  output:
    path 'residualGroupStats.txt'

  script:
    template 'calculateResidualGroupResults.bash'
}


/**
 * Combine the core + peripheral and residual groups file
 *
 * @param coreAndPeripheralGroupFile: core + peripheral group file
 * @param residualGroupFile: residual group file
 * @return fullGroupFile The combined group file
*/
process combineGroupFiles {
  container = 'veupathdb/orthofinder'

  input:
    path coreAndPeripheralGroupFile
    path residualGroupFile

  output:
    path 'fullGroupFile.txt'

  script:
    """
    cp $coreAndPeripheralGroupFile fullGroupFile.txt
    cat $residualGroupFile >> fullGroupFile.txt
    """
}


process makeFullDiamondDatabaseWithGroups {
  container = 'veupathdb/orthofinder'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path fullProteome
    path fullGroupFile
    val buildVersion

  output:
    path '*.dmnd'

  script:
    """
    createDiamondDatabaseWithGroups.pl --groups $fullGroupFile --proteome $fullProteome
    diamond makedb --in fastaWithGroups.fasta --db ortho${buildVersion}db.dmnd
    """
}


workflow residualWorkflow {
  take:
    inputFile
    coreBestRepsFasta
    coreAndPeripheralProteome
    coreAndPeripheralGroups
    coreOrResidual

  main:
    // prepare input proteomes in format orthoFinder needs
    proteomesForOrthofinder = moveUnambiguousAminoAcidSequencesFirst(inputFile).collect()

    // internal fastas and sequence/species id mappings
    setup = orthoFinderSetup(proteomesForOrthofinder)

    // create empty dir as we are processing residuals
    mappedCachedBlasts = createEmptyDir(setup.speciesMapping).collect()

    // get lists of species names and internal ids
    speciesIds = speciesFileToList(setup.speciesMapping, 0);
    speciesNames = speciesFileToList(setup.speciesMapping, 1);

    // make tuple object for processing pairwise combinations of species
    speciesPairsAsTuple = listToPairwiseComparisons(speciesIds, 250);

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

    // Final output format of residual groups. Adding R for residual, and build version.
    residualGroupsFile = reformatResidualGroupsFile(orthofinderGroupResults.orthologgroups, params.buildVersion)

    residualFasta = createResidualFasta(proteomesForOrthofinder)

    residualProteomesByGroup = splitProteomeByGroup(residualFasta.collect(), residualGroupsFile.splitText( by: 10000, file: true ))

    createGeneTrees(residualProteomesByGroup.collect().flatten().collate(50))
    
    // publish results
    publishOFResults(orthofinderGroupResults.results)    

    // make one file per species containing all ortholog groups for that species
    speciesOrthologs = splitOrthologGroupsPerSpecies(speciesNames.flatten(),
                                                      setup.speciesMapping.collect(),
                                                      setup.sequenceMapping.collect(),
                                                      orthofinderGroupResults.orthologgroups.collect(),
                                                      params.buildVersion,
                                                      coreOrResidual);

    // per species, make One file all diamond similarities for that group
    diamondSimilaritiesPerGroup = makeOrthogroupDiamondFile(diamondResultsFile.collect(),
                                                            speciesOrthologs.orthologs.collectFile(name: 'orthologs.txt'))
							     
    allDiamondSimilaritiesPerGroup = diamondSimilaritiesPerGroup.blastsByOrthogroup.flatten()

    // make a collection containing all group similarity files
    allDiamondSimilarities = allDiamondSimilaritiesPerGroup.collect()

    // make a collection of singletons files (one for each species)
    singletonFiles = speciesOrthologs.singletons.collect()

    // in batches, process group similarity files and determine best representative for each group
    bestRepresentatives = findResidualBestRepresentatives(allDiamondSimilaritiesPerGroup.collate(250),
     	                                                  residualGroupsFile.collect(),
     							  setup.sequenceMapping.collect())

    allBestRepresentatives = bestRepresentatives.flatten().collectFile()

    singletonsFull = makeFullResidualSingletonsFile(singletonFiles,
                                                    params.buildVersion).collectFile()

    // collect File of best representatives
    combinedBestRepresentatives = removeEmptyGroups(singletonsFull,
                                                    allBestRepresentatives)

    // make best rep file with actual sequence Ids
    translatedBestRepsFile = translateBestRepsFile(setup.sequenceMapping,
                                                   combinedBestRepresentatives,
			                           coreOrResidual)

    

    // fasta file with all seqs for best representative sequence wirh defline as group id
    bestRepresentativeFasta = makeResidualBestRepresentativesFasta(combinedBestRepresentatives,
                                                                   setup.orthofinderWorkingDir)

    // Create a residual specific mash result file for every core group fasta
    mashResults = runMash(residualProteomesByGroup.collect().flatten().collate(2000),
                          bestRepresentativeFasta.collect())

    // Calculate residual group stats
    calculateGroupResults(mashResults).collectFile(name: "residual_stats.txt",
                                                   storeDir: params.outputDir + "/groupStats")

    coreAndResidualBestRepFasta = mergeCoreAndResidualBestReps(bestRepresentativeFasta,
                                                               coreBestRepsFasta)

    // As we get new residual groups we need to compare core best reps
    coreBestRepsSubset = coreBestRepsFasta.splitFasta(by:1000, file:true)

    // run diamond for best representatives to find similar ortholog groups
    bestRepsSelfDiamond(coreBestRepsSubset,coreAndResidualBestRepFasta).collectFile(name: 'similar_groups.tsv',
                                                                                    storeDir: params.outputDir)

    fullOrthoProteome = combineProteomes(coreAndPeripheralProteome,residualFasta)

    combinedGroupFile = combineGroupFiles(coreAndPeripheralGroups,residualGroupsFile)

    makeFullDiamondDatabaseWithGroups(fullOrthoProteome,combinedGroupFile,params.buildVersion)
}

