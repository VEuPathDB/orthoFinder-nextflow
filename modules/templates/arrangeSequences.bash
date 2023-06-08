#!/usr/bin/env bash

set -euo pipefail

cp -r $fastaDir hold
rm -rf $fastaDir

for f in hold/*; do mv "\$f" .; done
rm -r hold
for f in *; do mv "\$f" "\$f.fasta"; done
mkdir fastas
for f in *.fasta; do perl /usr/bin/arrangeSequences.pl --input "\$f" --output "./fastas/\$f"; done

tar czvf fasta.tar.gz fastas 
