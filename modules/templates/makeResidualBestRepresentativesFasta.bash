#!/usr/bin/env bash

set -euo pipefail

SEQIDS=sequenceIds.txt

samtools faidx $residualFasta

cut -f 2 $bestRepresentatives > \$SEQIDS

# this will get fasta for all seq ids

samtools faidx -r \$SEQIDS $residualFasta | makeBestRepresentativesFasta.pl --bestReps $bestRepresentatives --outputFile bestReps.fasta

echo "Done"


