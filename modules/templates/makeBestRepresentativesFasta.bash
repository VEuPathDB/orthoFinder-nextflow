#!/usr/bin/env bash

set -euo pipefail

touch bestReps.txt
for f in *.final; do cat "\$f" >> bestReps.txt; done
cat Singletons.dat >> bestReps.txt
samtools faidx $fasta
perl /usr/bin/makeBestRepresentativesFasta.pl --bestReps bestReps.txt --fasta $fasta
