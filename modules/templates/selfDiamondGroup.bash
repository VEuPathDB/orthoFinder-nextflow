#!/usr/bin/env bash

set -euo pipefail

groupId=\$(basename $groupFasta .fasta)

diamond makedb --in $groupFasta --db groupdb

diamond blastp -d groupdb -q $groupFasta -o \${groupId}.sim -f 6 $outputList \
    --very-sensitive --no-self-hits
