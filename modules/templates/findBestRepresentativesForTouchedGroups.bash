#!/usr/bin/env bash

set -euo pipefail

touch combined.sim
if ls *.sim >/dev/null 2>&1; then
    tail -n +1 *.sim > combined.sim
fi

touch touchedBestReps.txt
findBestRepresentatives.pl --groupFile combined.sim >> touchedBestReps.txt

findMissingSimGroups.pl --groupList $touchedGroups --simDir . --output missingTouchedGroups.txt

addMissingGroupMembers.pl --missingGroups missingTouchedGroups.txt --groupMapping $groupFile >> touchedBestReps.txt
