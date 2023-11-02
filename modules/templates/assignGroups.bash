#!/usr/bin/env bash

set -euo pipefail

#TODO remove this
PATH=/home/jbrestel/project_home/orthoFinder/bin:$PATH

assignGroupsForPeripherals.pl --result $diamondInput \
			      --output groups.txt

sort -k 2 groups.txt > sortedGroups.txt

rm groups.txt
#sort -k 2 $diamondInput > sortedResults.txt
