#!/usr/bin/env bash

set -euo pipefail

makeResidualAndPeripheralFastas.pl --groups $groups \
				   --seqFile $seqFile \
				   --residuals residuals.fasta \
				   --peripherals peripherals.fasta

organism=\$(basename $seqFile .fasta)
coreAssignedCount=\$(grep -c "^>" peripherals.fasta || true)
residualCount=\$(grep -c "^>" residuals.fasta || true)
totalCount=\$((coreAssignedCount + residualCount))

printf "%s\t%s\t%s\t%s\n" "\$organism" "\$coreAssignedCount" "\$residualCount" "\$totalCount" > organismGroupCounts.tsv
