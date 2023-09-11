#!/usr/bin/env bash

set -euo pipefail

cat ${bestRepsBlast} | sort -k 1 > sorted.out

perl /usr/bin/formatSimilarOrthogroups.pl --input sorted.out --output similarOrthogroups.txt
