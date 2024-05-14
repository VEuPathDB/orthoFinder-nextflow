#!/usr/bin/env bash

set -euo pipefail

sort -k 1 $bestRepsTsv > sorted.tsv

calculateResidualGroupResults.pl --outputFile residualGroupStats.txt \
				 --bestRepResults sorted.tsv \
				 --evalueColumn $evalueColumn
