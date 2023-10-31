#!/usr/bin/env bash

set -euo pipefail

assignGroupsForPeripherals.pl --result $diamondInput \
			      --output groups.txt

sort -k 2 groups.txt > sortedGroups.txt


#sort -k 2 $diamondInput > sortedResults.txt
