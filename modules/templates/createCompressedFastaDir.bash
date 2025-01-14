#!/usr/bin/env bash

set -euo pipefail
mkdir fastas
separateFastaByOrganism.pl --inputFasta $inputFasta --proteomeDir ./proteomes --outputDir fastas
tar -zcvf fastas.tar.gz fastas
