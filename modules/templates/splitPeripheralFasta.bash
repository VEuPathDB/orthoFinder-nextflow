#!/usr/bin/env bash

set -euo pipefail
mkdir fastas
separateFastaByOrganism.pl --input $inputFasta --outputDir fastas
