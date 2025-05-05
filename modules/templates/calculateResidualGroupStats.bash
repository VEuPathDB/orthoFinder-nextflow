#!/usr/bin/env bash

set -euo pipefail

mkdir groupDiamondResults
mv *.sim groupDiamondResults
calculateResidualGroupStatistics.pl --inputDir groupDiamondResults \
                                    --bestRepFile $bestRepresentatives \
			            --groupsFile $groupsFile \
			            --missingGroups $missingGroups \
			            --outputFile groupStats.txt
