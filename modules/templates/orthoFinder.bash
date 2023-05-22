#!/usr/bin/env bash

set -euo pipefail

if [[ "$tarfile" == *".gz"* ]];then
    tar xzf $tarfile
    rm *.tar.gz
else
    tar xf $tarfile
    rm *.tar
fi

mv **/* .
rm -r */

for f in *; do mv "\$f" "\$f.fasta"; done

mkdir data
mv *.fasta data
orthofinder -f data -o ./results
mv results/Results*/* results
rm -rf results/Results_*
