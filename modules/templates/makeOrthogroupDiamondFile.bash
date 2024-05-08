#!/usr/bin/env bash

set -euo pipefail

SPECIES_0_ORTHOLOGS=${target}.orthologs

for query in ${queries.join(' ')}; do
    SPECIES_1_ORTHOLOGS=\$query.orthologs

    DIAMOND_FILE=${blastsDir}/Blast${target}_\${query}.txt
    OUTPUT_FILE=OrthologGroup_Blast\${query}_${target}.txt

    makeOrthologGroupDiamondFiles.pl --species0 \$SPECIES_0_ORTHOLOGS \
				     --species1 \$SPECIES_1_ORTHOLOGS \
				     --diamondFile \$DIAMOND_FILE \
				     --outputFile \$OUTPUT_FILE;
    sort \$OUTPUT_FILE >\$OUTPUT_FILE.sorted
    rm \$OUTPUT_FILE
done;

echo "Done"
