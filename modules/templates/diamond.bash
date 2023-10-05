#!/usr/bin/env bash

set -euo pipefail

for query in ${queries.join(' ')}; do

    BLAST_FILE=$mappedBlastCache/Blast\${query}_${target}.txt
    if [ -f "\$BLAST_FILE" ]; then
        echo "Taking from Cache for \$BLAST_FILE"
        ln -s \$BLAST_FILE .
    else
        # TODO:  Review the command line options here!

        echo "Running Diamond to generate Blast\${query}_${target}.txt"

        diamond blastp --ignore-warnings -d ${orthofinderWorkingDir}/diamondDBSpecies${target}.dmnd -q ${orthofinderWorkingDir}/Species\${query}.fa -o Blast\${query}_${target}.txt.gz -f 6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore --more-sensitive -p 1 --quiet -e 0.001 --compress 1
        gunzip Blast*.gz
    fi



done
