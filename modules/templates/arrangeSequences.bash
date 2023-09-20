#!/usr/bin/env bash

set -euo pipefail



mkdir arrangedFastas

for f in $fastaDir/*.fasta; do arrangeSequences.pl --input "\$f" --output "./arrangedFastas/\$f"; done
