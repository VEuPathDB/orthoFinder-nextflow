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
      -f 6 qseqid sseqid evalue \
      --comp-based-stats 0
fi
