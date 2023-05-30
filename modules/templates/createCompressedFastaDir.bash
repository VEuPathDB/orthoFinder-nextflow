#!/usr/bin/env bash

set -euo pipefail

mkdir fastas

perl /usr/bin/organismSeperateFastaFile.pl --input $inputFasta --outputDir fastas

tar czvf fasta.tar.gz fastas 
