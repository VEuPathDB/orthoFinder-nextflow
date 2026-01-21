include {bestRepsSelfDiamond; combineProteomes;
} from './shared.nf'


/**
* combine the core and residual fasta files containing best representative sequences
*
*/
process mergeCoreAndResidualBestReps {
  container = 'veupathdb/orthofinder:1.8.0'

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
 * Combine the core + peripheral and residual groups file
 *
 * @param coreAndPeripheralGroupFile: core + peripheral group file
 * @param residualGroupFile: residual group file
 * @return fullGroupFile The combined group file
*/
process combineGroupFiles {
  container = 'veupathdb/orthofinder:1.8.0'

  publishDir "$params.outputDir", mode: "copy"

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
  container = 'veupathdb/orthofinder:1.9.1'

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


process previousGroups {
  container = 'veupathdb/orthofinder:1.8.0'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path newGroupsFile
    path oldGroupsFile

  output:
    path 'previousGroups.txt'

  script:
    template 'previousGroups.bash'
}


workflow postProcessingWorkflow {
  take:
    coreBestRepsFasta

  main:
    coreAndResidualBestRepFasta = mergeCoreAndResidualBestReps(params.residualBestRepsFasta,
                                                               coreBestRepsFasta)

    // As we get new residual groups we need to compare core best reps
    coreBestRepsSubset = coreBestRepsFasta.splitFasta(by:1000, file:true)

    // run diamond for best representatives to find similar ortholog groups
    bestRepsSelfDiamond(coreBestRepsSubset,coreAndResidualBestRepFasta).collectFile(name: 'similar_groups.tsv',
                                                                                    storeDir: params.outputDir)

    fullOrthoProteome = combineProteomes(params.coreAndPeripheralProteome,params.residualFasta)

    combinedGroupFile = combineGroupFiles(params.coreAndPeripheralGroups,params.residualGroups)

    // Add new functionality here
    previousGroups(combinedGroupFile,params.oldGroupsFile)

    makeFullDiamondDatabaseWithGroups(fullOrthoProteome,combinedGroupFile,params.buildVersion)
}

