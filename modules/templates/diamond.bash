#!/usr/bin/env bash

set -euo pipefail

for query in ${queries.join(' ')}; do
    BLAST_FILE=$mappedBlastCache/Blast\${query}_${target}.txt
    if [ -f "\$BLAST_FILE" ]; then
        echo "Taking from Cache for \$BLAST_FILE"
        ln -s \$BLAST_FILE .
    else
        echo "Running Diamond to generate Blast\${query}_${target}.txt"
        diamond blastp --ignore-warnings \
		-d ${orthofinderWorkingDir}/diamondDBSpecies${target}.dmnd \
		-q ${orthofinderWorkingDir}/Species\${query}.fa \
		-o Blast\${query}_${target}.txt \
		-f 6 $outputList \
		--very-sensitive \
		--no-self-hits \
		-p 1 \
		--quiet
    fi
done
