#!/usr/bin/env bash

set -euo pipefail

# unpack the tarball;  need to know the directory name which is unpacked
tar -xvzf $coreDir >tarOut
tarDir=`cat tarOut | head -1 | cut -f1 -d"/"`

touch core.fasta

for f in \$tarDir/*.fasta; do cat \$f >> core.fasta; done


