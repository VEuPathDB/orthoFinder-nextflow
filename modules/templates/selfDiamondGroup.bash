#!/usr/bin/env bash

set -euo pipefail

# Without --threads, diamond auto-detects and uses every core on the node,
# regardless of how many this task was actually allocated. Groups here are
# processed one at a time in this loop (each one small, per the process doc),
# so there's no benefit to multithreading a single group -- but with many
# selfDiamondGroup batches landing on the same shared node at once, each
# secretly grabbing every core, diamond ends up badly oversubscribed and a
# batch can take hours instead of seconds. Pin to the single core this task
# is actually given (matches the process's cpus directive) so it can't
# contend for cores it doesn't have.
for groupFasta in $groupFastas; do
    groupId=\$(basename "\$groupFasta" .fasta)

    diamond makedb --threads 1 --in "\$groupFasta" --db "\${groupId}_db"

    diamond blastp --threads 1 -d "\${groupId}_db" -q "\$groupFasta" -o "\${groupId}.sim" -f 6 $outputList \
        --very-sensitive --no-self-hits
done
