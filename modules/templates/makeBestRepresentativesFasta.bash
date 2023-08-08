#!/usr/bin/env bash

set -euo pipefail
samtools faidx $fasta
perl /usr/bin/makeBestRepresentativesFasta.pl --bestReps $bestReps --fasta $fasta
