#!/usr/bin/env bash

set -euo pipefail

for f in *.sim;
do
    findBestRepresentatives.pl --groupFile "\$f" --output_file "\${f}.out";
    cat \${f}.out >> best_representative.txt
    rm \${f}.out
done
