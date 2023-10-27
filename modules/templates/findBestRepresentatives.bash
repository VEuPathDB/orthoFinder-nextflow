#!/usr/bin/env bash

set -euo pipefail

for f in *.sim;
do
    findBestRepresentatives.pl --groupFile "\$f" >> best_representative.txt;
done
