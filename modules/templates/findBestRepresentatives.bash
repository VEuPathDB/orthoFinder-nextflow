#!/usr/bin/env bash

set -euo pipefail

tail -n +1 *.sim > combined.sim

findBestRepresentatives.pl --groupFile combined.sim >> untranslated_best_reps.txt

addMissingGroupMembers.pl \
    --missingGroups $missingGroups \
    --groupMapping $groupMapping \
    >> untranslated_best_reps.txt

translateBestRepsFile.pl --bestReps untranslated_best_reps.txt --sequenceIds SequenceIDs.txt --outputFile best_representative.txt
