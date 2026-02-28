include {splitOrthologGroupsPerSpecies; makeOrthogroupDiamondFile;
	 splitProteomeByGroup; speciesFileToList;
} from './shared.nf'


/**
* combine species residual singletons file.
*/
process makeFullResidualSingletonsFile {
  container = 'veupathdb/orthofinder:1.9.3'

  input:
    path singletonFiles
    val buildVersion

  output:
    path 'singletonsFull.dat'

  script:
    template 'makeFullResidualSingletonsFile.bash'
}



process reformatResidualGroupsFile {
  container = 'veupathdb/orthofinder:1.9.3'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path groupsFile
    val buildVersion
    val residualBuildVersion

  output:
    path 'reformattedGroups.txt', emit: groups
    path 'buildVersion.txt'

  script:
    template 'reformatResidualGroupsFile.bash'
}


/**
*  for each group, determine which residual sequence has the lowest average evalue
*/
process findResidualBestRepresentatives {
  container = 'veupathdb/orthofinder:1.9.3'

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
  container = 'veupathdb/orthofinder:1.9.3'

  publishDir "$params.outputDir/", mode: "copy"

  input:
    path bestRepresentatives
    path residualFasta

  output:
    path 'bestReps.fasta'

  script:
    template 'makeResidualBestRepresentativesFasta.bash'
}


/**
*  Translate best rep file to hold actual sequenceIds, not OF internal ids
*/
process translateBestRepsFile {
  container = 'veupathdb/orthofinder:1.9.3'

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
 * checkForMissingGroups
 *
 * @param allDiamondSimilarities: All group specific pairwise blast results
 * @param buildVersion: Current build version
 * @param groupsFile: Residual groups file
 * @return A file that lists all of the groups that do not have a file present
*/
process checkForMissingGroups {
  container = 'veupathdb/orthofinder:1.9.3'

  input:
    path allDiamondSimilarities
    val buildVersion
    val residualBuildVersion
    path groupsFile

  output:
    path 'missingGroups.txt'

  script:
    """
    checkForResidualMissingGroups.pl . $buildVersion $residualBuildVersion $groupsFile
    """
}

process calculateResidualGroupStats {
  container = 'veupathdb/orthofinder:1.9.3'

  input:
    path bestRepresentatives
    path similarities
    path groupsFile
    path missingGroups

  output:
    path 'groupStats.txt'

  script:
    template 'calculateResidualGroupStats.bash'
}


process  createIntraResidualGroupBlastFile {
  container = 'veupathdb/orthofinder:1.9.3'

  publishDir "$params.outputDir/", mode: "copy"

  input:
    path blastFiles
    path translateFile
    path bestReps

  output:
    path 'intraResidualGroupBlastFile.tsv'

  script:
    template 'createIntraResidualGroupBlastFile.bash'
}


workflow postResidualWorkflow {
  take:
    groupsFile

  main:

    // Final output format of residual groups. Adding R for residual, and build version.
    residualGroupsFile = reformatResidualGroupsFile(groupsFile, params.buildVersion, params.residualBuildVersion)

    residualProteomesByGroup = splitProteomeByGroup(params.residualFasta, residualGroupsFile.groups.splitText( by: 10000, file: true ))

    // get lists of species names and internal ids
    speciesFile = Channel.fromPath( params.speciesMapping )
    sequenceFile = Channel.fromPath( params.sequenceMapping )

    speciesIdsList = speciesFileToList(speciesFile, 0);
    speciesNames = speciesFileToList(speciesFile, 1);

    // make one file per species containing all ortholog groups for that species
    speciesOrthologs = splitOrthologGroupsPerSpecies(speciesNames.flatten(),
                                                      speciesFile,
                                                      sequenceFile,
                                                      groupsFile.collect(),
                                                      params.buildVersion,
                                                      params.residualBuildVersion,
                                                      "residual");

    // per species, make One file all diamond similarities for that group
    diamondSimilaritiesPerGroup = makeOrthogroupDiamondFile(params.diamondResultsFile,
                                                            speciesOrthologs.orthologs.collectFile(name: 'orthologs.txt'))

    allDiamondSimilaritiesPerGroup = diamondSimilaritiesPerGroup.blastsByOrthogroup.flatten()

    // make a collection containing all group similarity files
    allDiamondSimilarities = diamondSimilaritiesPerGroup.blastsByOrthogroup.flatten().collect()

    // make a collection of singletons files (one for each species)
    singletonFiles = speciesOrthologs.singletons.collect()

    // in batches, process group similarity files and determine best representative for each group
    bestRepresentatives = findResidualBestRepresentatives(allDiamondSimilaritiesPerGroup.collate(250),
     	                                                  residualGroupsFile.groups.collect(),
     							  params.sequenceMapping)

    allBestRepresentatives = bestRepresentatives.flatten().collectFile()

    singletonsFull = makeFullResidualSingletonsFile(singletonFiles,
                                                    params.buildVersion).collectFile()

    // collect File of best representatives
    combinedBestRepresentatives = removeEmptyGroups(singletonsFull,
                                                    allBestRepresentatives)

    // make best rep file with actual sequence Ids
    translatedBestRepsFile = translateBestRepsFile(params.sequenceMapping,
                                                   combinedBestRepresentatives,
			                           "residual")

    createIntraResidualGroupBlastFile(diamondSimilaritiesPerGroup.collect(), params.sequenceMapping, translatedBestRepsFile)
    

    // fasta file with all seqs for best representative sequence wirh defline as group id
    bestRepresentativeFasta = makeResidualBestRepresentativesFasta(translatedBestRepsFile,
                                                                   params.residualFasta)

    missingGroups = checkForMissingGroups(allDiamondSimilarities.flatten().collect(),
                                          params.buildVersion,
					  params.residualBuildVersion,
    					  residualGroupsFile.groups).collect()

    // Calculate residual group stats
    calculateResidualGroupStats(combinedBestRepresentatives, allDiamondSimilarities, residualGroupsFile.groups, missingGroups).collectFile(name: "residual_stats.txt", storeDir: params.outputDir + "/groupStats")

}

