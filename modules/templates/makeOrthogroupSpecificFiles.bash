#!/usr/bin/env bash

set -euo pipefail
mv Results*/Orthogroups/Orthogroups.txt ./Orthogroups
rm -rf Results*
gunzip -d --force *.gz
mkdir GroupFiles
perl /usr/bin/makeOrthogroupSpecificFiles.pl --groupsFile Orthogroups
rm *.txt
