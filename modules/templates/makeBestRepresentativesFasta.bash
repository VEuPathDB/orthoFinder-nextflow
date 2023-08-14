#!/usr/bin/env bash

set -euo pipefail
cat $singletons >> $bestReps
samtools faidx $fasta
perl /usr/bin/makeBestRepresentativesFasta.pl --bestReps $bestReps --fasta $fasta
