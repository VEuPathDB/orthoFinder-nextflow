#!/usr/bin/env bash

set -euo pipefail

OUTPUT=bestReps.fasta
SEQIDS=sequenceIds.txt

samtools faidx $proteome

cut -f 2 $bestRepresentatives >\$SEQIDS

samtools faidx -r \$SEQIDS $proteome | makeBestRepresentativesFasta.pl --bestReps $bestRepresentatives --outputFile \$OUTPUT

echo "Done"


