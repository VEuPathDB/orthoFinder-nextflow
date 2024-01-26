#!/usr/bin/env bash

set -euo pipefail

diamond makedb --in $bestRepsFasta --db newdb
diamond blastp \
  -d newdb.dmnd \
  -q $bestRepSubset \
  -o bestReps.out \
  -e 0.00001 \
  -f 6 $params.bestRepDiamondOutputFields \
  --comp-based-stats 0 \
  --no-self-hits

