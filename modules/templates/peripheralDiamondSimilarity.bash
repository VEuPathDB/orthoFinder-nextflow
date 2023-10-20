#!/usr/bin/env bash

set -euo pipefail

BLAST_FILE=$peripheralDiamondCache/${fasta}.out

if [ -f "\$BLAST_FILE" ]; then
        echo "Taking from Cache for \$BLAST_FILE"
        ln -s \$BLAST_FILE .
else
    diamond blastp \
      -d $database \
      -q $fasta \
      -o ${fasta}.out \
      -f 6 $outputList \
      --comp-based-stats 0

    cat ${fasta}.out | sort -k 2 > diamondSimilarity.out
    mv diamondSimilarity.out ${fasta}.out
fi


