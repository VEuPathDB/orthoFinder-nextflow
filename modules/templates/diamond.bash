#!/usr/bin/env bash

set -euo pipefail

mkdir -p blastBatch_${target}_${queries[0]}

for query in ${queries.join(' ')}; do
    BLAST_FILE=$mappedBlastCache/Blast\${query}_${target}.txt
    if [ -f "\$BLAST_FILE" ]; then
        echo "Taking from Cache for \$BLAST_FILE"
        ln -s \$BLAST_FILE blastBatch_${target}_${queries[0]}/
    else
        echo "Running Diamond to generate Blast\${query}_${target}.txt"
        diamond blastp --ignore-warnings \
		-d ${orthofinderWorkingDir}/diamondDBSpecies${target}.dmnd \
		-q ${orthofinderWorkingDir}/Species\${query}.fa \
		-o blastBatch_${target}_${queries[0]}/Blast\${query}_${target}.txt \
		-f 6 $outputList \
		--very-sensitive \
		--no-self-hits \
		-p 1 \
		--quiet
    fi
done
