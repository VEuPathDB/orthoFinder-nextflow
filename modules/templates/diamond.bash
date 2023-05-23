#!/usr/bin/env bash

set -euo pipefail

diamond blastp --ignore-warnings -d $dataFile -q $queryFile -o $outputPath --more-sensitive -p 1 --quiet -e 0.001 --compress 1

touch done.txt
