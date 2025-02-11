#!/usr/bin/env bash

set -euo pipefail

FASTA=proteome.fasta
SEQIDS=sequenceIds.txt

OUTPUT=bestReps.fasta

cat $orthofinderWorkingDir/*.fa >\$FASTA

samtools faidx \$FASTA

cut -f 2 $bestRepresentatives >\$SEQIDS

# this will get fasta for all seq ids

samtools faidx -r \$SEQIDS \$FASTA | makeBestRepresentativesFasta.pl --bestReps $bestRepresentatives --outputFile \$OUTPUT

echo "Done"


