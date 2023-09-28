#!/usr/bin/env bash

set -euo pipefail

for f in *.final; do translateBestReps.pl --bestRepFile "\$f" --sequenceFile $sequenceMapping; done

touch bestReps.txt
for f in *.final; do cat "\$f" >> bestReps.txt; done
cat Singletons.dat >> bestReps.txt
if [[ $fasta == *.tar.gz ]]; then
    tar -xf $fasta
    touch proteome.txt
    for f in **/*.fasta; do cat "\$f" >> proteome.txt; done
    mv proteome.txt proteome.fasta
    samtools faidx proteome.fasta
    makeBestRepresentativesFasta.pl --bestReps bestReps.txt --fasta proteome.fasta
else
    mv $fasta proteome.fasta
    samtools faidx proteome.fasta
    makeBestRepresentativesFasta.pl --bestReps bestReps.txt --fasta proteome.fasta --is_residual
fi



