#!/usr/bin/env bash

set -euo pipefail

perl /usr/bin/printSimSeqs.pl \
  --result $reformattedBlastOutput \
  --output printSimSeqs.out \
  --minLen $lengthCutoff \
  --minPercent $percentCutoff \
  --minPval $pValCutoff \
  --remMaskedRes $adjustMatchLength
