#!/usr/bin/env bash

set -euo pipefail

exit 1;

gunzip -d --force *.gz
mkdir GroupFiles
perl /usr/bin/makeOrthogroupSpecificFiles.pl --groupsFile $orthoGroupsFile
rm *.txt
mv GroupFiles/* .
rm -rf GroupFiles
