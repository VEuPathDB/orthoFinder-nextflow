#!/usr/bin/env bash

set -euo pipefail

mkdir arrangedProteomes

# unpack the tarball;  need to know the directory name which is unpacked
tar -xvzf $proteomes >tarOut
tarDir=`cat tarOut | head -1 | cut -f1 -d"/"`

for f in \$tarDir/*.fasta;
do
    moveUnambiguousAminoAcidSequencesFirst.pl --input \$f --ambiguous "\${f}.ambiguous" --unambiguous "\${f}.unambiguous";
    cat \${f}.unambiguous \${f}.ambiguous >arrangedProteomes/\${f##*/}
    rm \${f}.unambiguous \${f}.ambiguous
done
