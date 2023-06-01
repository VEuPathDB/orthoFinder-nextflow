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
orthofinder -f input -op
mv input/OrthoFinder/**/WorkingDirectory/*.txt .
mv input/OrthoFinder/**/WorkingDirectory/*.fa .
mv input/OrthoFinder/**/WorkingDirectory/*.dmnd .
