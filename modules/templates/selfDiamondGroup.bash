#!/usr/bin/env bash

set -euo pipefail

# Groups are processed strictly sequentially in this loop, so a single group
# whose diamond calls hang (pathological low-complexity/degenerate content --
# seen repeatedly in production) blocks every remaining group in the batch
# forever, since diamond never returns and never exits nonzero. Cap each
# group's makedb/blastp at PER_GROUP_TIMEOUT and skip it on timeout or
# failure instead: findBestRepresentativesForTouchedGroups already falls
# back to the existing representative for any touched group left with no
# *.sim file (findMissingSimGroups.pl / addMissingGroupMembers.pl), so a
# skipped group here is a tolerated, documented outcome -- not data loss.
PER_GROUP_TIMEOUT=15m

for groupFasta in $groupFastas; do
    groupId=\$(basename "\$groupFasta" .fasta)

    if ! timeout --kill-after=1m "\$PER_GROUP_TIMEOUT" \
        diamond makedb --in "\$groupFasta" --db "\${groupId}_db"; then
        echo "selfDiamondGroup: \$groupId timed out or failed at makedb -- skipping" >&2
        rm -f "\${groupId}_db.dmnd"
        continue
    fi

    if ! timeout --kill-after=1m "\$PER_GROUP_TIMEOUT" \
        diamond blastp -d "\${groupId}_db" -q "\$groupFasta" -o "\${groupId}.sim" -f 6 $outputList \
        --very-sensitive --no-self-hits; then
        echo "selfDiamondGroup: \$groupId timed out or failed at blastp -- skipping" >&2
        rm -f "\${groupId}.sim"
        continue
    fi
done
