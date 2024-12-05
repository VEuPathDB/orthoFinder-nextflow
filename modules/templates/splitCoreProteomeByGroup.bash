#!/usr/bin/env bash

set -euo pipefail

for f in $proteome/*.fasta; do cat \$f >> coreProteome.fasta; done

splitCoreProteomeByGroup.pl \
    --groups $groups \
    --proteome coreProteome.fasta
