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

mkdir input
mv *.fasta input
orthofinder -f input -op > commands
mv input/OrthoFinder/**/WorkingDirectory/*.txt .
cp input/OrthoFinder/**/WorkingDirectory/*.fa .

