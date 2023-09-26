#!/usr/bin/env bash

set -euo pipefail


# if the Blast file is in the mapped cache use it, otherwise make new with diamond
BLAST_FILE=$mappedBlastCache/Blast${pair[1]}_${pair[0]}.txt
if [ -f "\$BLAST_FILE" ]; then
    echo "Taking from Cache for \$BLAST_FILE"
    ln -s \$BLAST_FILE .
else
    # TODO:  Review the command line options here!
    diamond blastp --ignore-warnings -d ${orthofinderWorkingDir}/diamondDBSpecies${pair[0]}.dmnd -q ${orthofinderWorkingDir}/Species${pair[1]}.fa -o Blast${pair[1]}_${pair[0]}.txt.gz -f 6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qlen slen nident positive qframe qstrand gaps qcovhsp scovhsp qseq --more-sensitive -p 1 --quiet -e 0.001 --compress 1
    gunzip Blast*.gz
fi
