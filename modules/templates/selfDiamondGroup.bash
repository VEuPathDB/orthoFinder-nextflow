#!/usr/bin/env bash

set -euo pipefail

for groupFasta in $groupFastas; do
    groupId=\$(basename "\$groupFasta" .fasta)

    diamond makedb --in "\$groupFasta" --db "\${groupId}_db"

    diamond blastp -d "\${groupId}_db" -q "\$groupFasta" -o "\${groupId}.sim" -f 6 $outputList \
        --very-sensitive --no-self-hits
done
