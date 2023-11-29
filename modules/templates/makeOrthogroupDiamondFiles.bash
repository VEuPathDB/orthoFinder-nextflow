#!/usr/bin/env bash

set -euo pipefail

SPECIES_0_ORTHOLOGS=${target}.orthologs

for query in ${queries.join(' ')}; do
    SPECIES_1_ORTHOLOGS=\$query.orthologs

    echo "Query is \$query"
    date
    
    DIAMOND_FILE=Blast${target}_\${query}.txt
    OUTPUT_FILE=OrthologGroup_Blast\${query}_${target}.txt

    makeOrthologGroupDiamondFiles.pl --species0 \$SPECIES_0_ORTHOLOGS \
				     --species1 \$SPECIES_1_ORTHOLOGS \
				     --diamondFile \$DIAMOND_FILE \
				     --outputFile \$OUTPUT_FILE;
    sort \$OUTPUT_FILE >\$OUTPUT_FILE.sorted
    rm \$OUTPUT_FILE

    echo "DoneMakeGroup"
    date
    
    # NOTE:  This script will append to OG files in this directory:   OGXXXXX.sim
    splitBlastsIntoGroupsFiles.pl --input_file \$OUTPUT_FILE.sorted \
				  --output_file_suffix ".sim"

    echo "Done \$query"
    date
    
done;

# NOTE: in real workflow, this will never be needed but for tests we need to always provide output files
touch empty.sim
chmod guo+rw *.sim
