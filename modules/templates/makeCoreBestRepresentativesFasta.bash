#!/usr/bin/env bash

set -euo pipefail

OUTPUT=coreBestReps.fasta
SEQIDS=sequenceIds.txt

samtools faidx $proteome

cut -f 2 $bestRepresentatives >\$SEQIDS

samtools faidx -r \$SEQIDS $proteome | makeBestRepresentativesFasta.pl --bestReps $bestRepresentatives --outputFile \$OUTPUT

cp $bestRepresentatives coreBestReps.txt

echo "Done"


