#!/usr/bin/env bash

set -euo pipefail

# unpack the tarball;  need to know the directory name which is unpacked
tar -xvzf $peripheralDir >tarOut
tarDir=`cat tarOut | head -1 | cut -f1`

touch peripheral.fasta

mkdir fastas

for f in \$tarDir/*.fasta; do cat \$f >> peripheral.fasta; done

for f in \$tarDir/*.fasta; do cp \$f fastas; done


