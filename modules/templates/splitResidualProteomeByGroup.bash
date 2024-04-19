#!/usr/bin/env bash

set -euo pipefail

sort -k 1 $groups > sortedGroups.txt

splitResidualProteomeByGroup.pl --groups sortedGroups.txt --proteome $proteome
