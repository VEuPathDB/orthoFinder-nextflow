#!/usr/bin/env bash

set -euo pipefail

mkdir fastas

perl /usr/bin/seperateFastaFile.pl --input $inputFasta --outputDir fastas --fastaSubsetSize $fastaSubsetSize

tar czvf fasta.tar.gz fastas 
