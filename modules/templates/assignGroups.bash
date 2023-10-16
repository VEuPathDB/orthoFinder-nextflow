#!/usr/bin/env bash

set -euo pipefail

assignGroupsForPeripherals.pl --result $sortedResults \
			      --output groups.txt

sort -k 2 groups.txt > sortedGroups.txt
sort -k 2 $sortedResults > sortedResults.txt
