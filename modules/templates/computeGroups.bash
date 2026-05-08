#!/usr/bin/env bash

set -euo pipefail

ln -s $orthofinderWorkingDir/* ./

for dir in blastBatch_*/; do
    for f in "\${dir}"Blast*.txt; do
        [ -f "\$f" ] && ln -sf "\$(realpath "\$f")" .
    done
done

orthofinder -a 5 -b .

#TODO:  what happens if there is more than one directory returned by this glob??
ln -s OrthoFinder/Results* ./Results
