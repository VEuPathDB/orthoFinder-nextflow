#!/usr/bin/env bash

set -euo pipefail

# Named so it can never itself match the "*.sim" glob below -- otherwise the
# accumulator file becomes one of its own inputs and the redirect turns into
# an unbounded self-referential read/write loop.
combined=combinedGroupSims.txt
touch \$combined

# Only feed non-empty .sim files to tail -- findBestRepresentatives.pl uses
# tail's "==> file <==" headers to detect group boundaries, so even an empty
# .sim file (a touched group whose members had zero pairwise hits above
# threshold -- a real outcome for a freshly-reassigned sequence) still gets a
# spurious entry with a blank representative. Groups with no similarity data
# are already correctly handled by addMissingGroupMembers.pl below.
# (Plain glob + bash's -s test, not `find -size`: staged inputs are symlinks,
# and `find -size` without -L checks the symlink's own length, not the
# target's -- always true. `find`'s "./"-prefixed paths would also corrupt
# every group ID captured from tail's headers below.)
nonEmptySims=""
for f in *.sim; do
    if [ -s "\$f" ]; then
        nonEmptySims="\$nonEmptySims \$f"
    fi
done
if [ -n "\$nonEmptySims" ]; then
    tail -n +1 \$nonEmptySims > \$combined
fi

touch touchedBestReps.txt
findBestRepresentatives.pl --groupFile \$combined >> touchedBestReps.txt

findMissingSimGroups.pl --groupList $touchedGroups --simDir . --output missingTouchedGroups.txt

addMissingGroupMembers.pl --missingGroups missingTouchedGroups.txt --groupMapping $groupFile >> touchedBestReps.txt
