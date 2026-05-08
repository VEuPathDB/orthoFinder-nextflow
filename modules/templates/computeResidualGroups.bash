#!/usr/bin/env bash

set -euo pipefail

ln -s $orthofinderWorkingDir/* ./

for dir in blastBatch_*/; do
    for f in "\${dir}"Blast*.txt; do
        [ -f "\$f" ] && ln -sf "\$(realpath "\$f")" .
    done
done

orthofinder -a 5 -b . -og

ln -s OrthoFinder/Results* ./Results

cp Results/Orthogroups/Orthogroups.txt .
