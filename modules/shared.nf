#!/usr/bin/env nextflow
nextflow.enable.dsl=2


def collectDiamondSimilaritesPerGroup(diamondSimilaritiesPerGroup) {
    return diamondSimilaritiesPerGroup
        .flatten()
        .collectFile() { item -> [ item.getName(), item ] }
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


/**
 * ortho finder checks for unambiguous amino acid sequences in  first few sequences of fasta.
 * ensure the first sequence in each fasta file has unambigous amino acids
 *
 * @param proteomes:  tar.gz directory of fasta files.  each named like $organismAbbrev.fasta
 * @return arrangedProteomes directory of fasta files
 *
 */
process moveUnambiguousAminoAcidSequencesFirst {
  container = 'veupathdb/orthofinder:1.3.0'

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
  container = 'veupathdb/orthofinder:1.3.0'

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
* take diamond results from mappedCache dir if they exist OR run diamond to create (and send to cache)
*
* @param pair of integers.  There will be lots of these
* @param orthofinderWorkingDir is the direcotry with the diamond indexes and fasta files
* @param mappedBlastCache is the directory of previous blast output mapped to this run
* @return Blast*.txt is the resulting file (either from cache or new)
*/
process diamond {
  container = 'veupathdb/diamondsimilarity:1.0.0'

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


process publishOFResults {
  container = 'veupathdb/orthofinder:1.3.0'
  
  publishDir "$params.outputDir", mode: "copy"

  input:
    path 'OrthoFinderResults'
  
  output:
    path 'Results'

  '''
  cp -r OrthoFinderResults Results
  '''
}


process uncompressFastas {
  container = 'veupathdb/orthofinder:1.3.0'

  input:
    path inputDir

  output:
    path 'hold', emit: proteomeDir
    path 'hold/*.fasta', emit: proteomes
    path 'output.fasta', emit: combinedProteomesFasta

  script:
    template 'uncompressFastas.bash'
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
    container = 'veupathdb/orthofinder:1.3.0'

    input:
    val species
    path speciesMapping
    path sequenceMapping
    path orthologgroups
    val buildVersion
    val residualBuildVersion
    val coreOrResidual

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
process makeOrthogroupDiamondFile {
  container = 'veupathdb/orthofinder:1.3.0'

  input:
    path blastFile
    path orthologs

  output:
    path 'OG*.sim', emit: blastsByOrthogroup

  script:
    template 'makeOrthogroupDiamondFile.bash'
}



process makeDiamondResultsFile {
  container = 'veupathdb/orthofinder:1.3.0'

  input:
    path blasts

  output:
    path 'blastsFile.txt'

  script:
    """
    for file in Blast*; do cat \$file >> blastsFile.txt; done
    """
}

process bestRepsSelfDiamond {
  container = 'veupathdb/diamondsimilarity:1.0.0'

  input:
    path bestRepSubset
    path bestRepsFasta

  output:
    path 'bestReps.out'

  script:
    template 'bestRepsSelfDiamond.bash'
}


/**
 * Create a gene tree per group
 *
 * @param fasta: A group fasta file from the keepSeqIdsFromDeflines process  
 * @return tree Output group tree file
*/
process createGeneTrees {
  container = 'veupathdb/orthofinder:1.3.0'

  publishDir "$params.outputDir/geneTrees", mode: "copy", pattern: "*.tree"
  publishDir "$params.outputDir/groupAlignments", mode: "copy", pattern: "*.alignment"

  input:
    path fasta

  output:
    path '*.tree', optional: true
    path '*.alignment', optional: true

  script:
    template 'createGeneTrees.bash'
}


/**
 *  Runs mash to generate group statistics
 *
 * @param fasta: A collection of group fasta files
 * @param bestRep: A fasta file of all the group best reps, with the groupID as the defline
 * @return A mash result file for every group to their best representative
*/
process runMash {
  container = 'veupathdb/orthofinder:1.3.0'

  input:
    path fasta
    path bestRep

  output:
    path "*.mash"

  script:
   """
   runMash.pl --inputDir . --bestRepFasta $bestRep
   """
}


/**
 * Split the combined core and peripheral proteome by group
 *
 * @param proteome: The full combined core and peripheral proteome
 * @param groups: The full groups file
 * @param outdated: The outdated organism file  
 * @return fasta A fasta file per group
*/
process splitProteomeByGroup {
  container = 'veupathdb/orthofinder:1.3.0'

  input:
    path proteome
    path groups

  output:
    path '*.fasta'

  script:
    template 'splitProteomeByGroup.bash'
}


/**
 * Combine the core and peripheral proteome
 *
 * @param coreProteome: A fasta file containing all of the core sequences
 * @param peripheralProteome: A fasta file containing all of the peripheral sequences
 * @return fullProteome The combined proteome fasta
*/
process combineProteomes {
  container = 'veupathdb/orthofinder:1.3.0'

  input:
    path '1.fasta'
    path '2.fasta'

  output:
    path 'fullProteome.fasta'

  script:
    template 'combineProteomes.bash'
}


process splitBySize {
  container = 'veupathdb/orthofinder:1.3.0'

  input:
    path fasta

  output:
    path 'large/*', optional: true, emit: large
    path 'small/*', optional: true, emit: small    

  script:
    """
    mkdir small
    mkdir large
    for f in *.fasta;
    do
      SEQ_COUNT=\$(grep ">" \$f | wc -l) 
      if [ "\$SEQ_COUNT" -le 10000 ]; then
	mv \$f small
      else
        mv \$f large
      fi	
    done
    """
}

process calculateGroupStats {
  container = 'veupathdb/orthofinder:1.3.0'

  input:
    path bestRepresentatives
    path similarities
    path groupsFile
    path translateFile
    path missingGroups
    val flatFiles

  output:
    path 'groupStats.txt'

  script:
    template 'calculateGroupStats.bash'
}