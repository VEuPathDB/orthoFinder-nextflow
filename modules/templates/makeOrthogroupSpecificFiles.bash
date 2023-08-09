#!/usr/bin/env bash

set -euo pipefail
gunzip -d --force *.gz
mkdir GroupFiles
perl /usr/bin/makeOrthogroupSpecificFiles.pl --groupsFile $orthoGroupsFile
rm *.txt
