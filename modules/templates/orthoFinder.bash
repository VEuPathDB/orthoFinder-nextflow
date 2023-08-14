#!/usr/bin/env bash

set -euo pipefail

rm cleaned.txt

if [[ "$tarfile" == *".gz"* ]];then
    tar xzf $tarfile
    rm *.tar.gz
else
    tar xf $tarfile
    rm *.tar
fi

for f in **/*; do mv "\$f" .; done

rm -r */

for f in *; do mv "\$f" "\$f.fasta"; done

mkdir input
for f in *.fasta; do mv "\$f" ./input; done

orthofinder -f input -op

for f in input/OrthoFinder/**/WorkingDirectory/*.txt; do mv "\$f" .; done
for f in input/OrthoFinder/**/WorkingDirectory/*.fa; do mv "\$f" .; done
for f in input/OrthoFinder/**/WorkingDirectory/*.dmnd; do mv "\$f" .; done
