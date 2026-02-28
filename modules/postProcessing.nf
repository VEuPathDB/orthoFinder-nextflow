include {bestRepsSelfDiamond; combineProteomes;
} from './shared.nf'


/**
* combine the core and residual fasta files containing best representative sequences
*
*/
process mergeCoreAndResidualBestReps {
  container = 'veupathdb/orthofinder:1.9.3'

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
  container = 'veupathdb/orthofinder:1.9.3'

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
  container = 'veupathdb/orthofinder:1.9.3'

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
  container = 'veupathdb/orthofinder:1.9.3'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path newGroupsFile
    path oldGroupsFile

  output:
    path 'previousGroups.txt'

  script:
    template 'previousGroups.bash'
}


/**
* Filter residual group fastas: keep only groups with 3 <= count < 1000.
* Groups >= 1000 are skipped for residual (no core filtering applies).
*/
process filterResidualGroups {
  container = 'veupathdb/orthofinder:1.9.3'

  input:
    path fasta

  output:
    path 'filtered/*', optional: true, emit: fastas

  script:
    """
    mkdir filtered
    for f in *.fasta; do
      [ -f "\$f" ] || continue
      SEQ_COUNT=\$(grep ">" \$f | wc -l)
      if [ "\$SEQ_COUNT" -ge 3 ] && [ "\$SEQ_COUNT" -lt 1000 ]; then
        cp \$f filtered/
      fi
    done
    """
}


/**
* Filter group fastas to only include core sequences, and remove groups with more than 1000 sequences
*/
process filterForCoreSequences {
  container = 'veupathdb/orthofinder:1.9.3'

  input:
    path fasta
    path coreSequences

  output:
    path 'filtered/*.fasta', optional: true, emit: filtered

  script:
    template 'filterForCoreSequences.bash'
}


/**
* Create gene trees using fast mafft alignment and fasttree
*/
process createFastGeneTrees {
  container = 'veupathdb/orthofinder:1.9.3'

  publishDir "$params.outputDir/geneTrees", mode: "copy"

  input:
    path fasta

  output:
    path '*.tree'

  script:
    template 'createFastGeneTrees.bash'
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

    // Fasttree gene tree pipeline
    coreGroupFastas = Channel.fromPath("${params.coreGroupFastas}/*.fasta")
    residualGroupFastas = Channel.fromPath("${params.residualGroupFastas}/*.fasta")

    // Residual: keep only groups with 3 <= count < 1000; skip >= 1000
    residualFiltered = filterResidualGroups(residualGroupFastas.collate(10000))

    // Core+peripheral: pass through if 3 <= count < 1000; if >= 1000, filter to
    // core sequences only and keep if the filtered result is 3 <= count < 1000
    coreFiltered = filterForCoreSequences(
        coreGroupFastas.collate(1000),
        params.coreAndPeripheralProteome
    )

    createFastGeneTrees(
        residualFiltered.fastas.mix(coreFiltered.filtered)
            .collect().flatten().collate(1000)
    )
}

