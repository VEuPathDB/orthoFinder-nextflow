#!/usr/bin/env bash

set -euo pipefail

mkdir final

# Need to do the core group results first. There may be core groups that contain not peripherals, but there will be no peripheral groups that do not contain any core proteins (those are the residuals)

for f in $coreGroupSimilarities/*bestRep.tsv;
do
    fname=\$(basename \$f)
    touch final/\$fname
    cat $coreGroupSimilarities/\$fname > final/\$fname
done

for f in *bestRep.tsv;
do
    cat \$f >> final/\$f
done


