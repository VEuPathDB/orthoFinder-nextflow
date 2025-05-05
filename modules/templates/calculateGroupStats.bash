#!/usr/bin/env bash

set -euo pipefail
if [ "$flatFiles" = true ]; then
    mkdir groupDiamondResults
    mv *.sim groupDiamondResults
    calculateGroupStatistics.pl --inputDir groupDiamondResults \
			         --bestRepFile $bestRepresentatives \
			         --groupsFile $groupsFile \
			         --translateFile $translateFile \
			         --missingGroups $missingGroups \
			         --outputFile groupStats.txt
else
    calculateGroupStatistics.pl --inputDir $similarities \
			         --bestRepFile $bestRepresentatives \
			         --groupsFile $groupsFile \
			         --translateFile $translateFile \
			         --missingGroups $missingGroups \
			         --outputFile groupStats.txt    
fi

