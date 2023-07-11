#!/usr/bin/env bash

set -euo pipefail

cp -r $fastaDir hold

for f in hold/*; do mv "\$f" ./\$f.fasta; done

for f in hold/*.fasta; do cp "\$f" .; done

mkdir newFastas

for f in *.fasta; do perl /usr/bin/arrangeSequences.pl --input "\$f" --output "./newFastas/\$f"; done

tar czvf fasta.tar.gz newFastas 
