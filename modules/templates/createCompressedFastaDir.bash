#!/usr/bin/env bash

set -euo pipefail

mkdir hold

perl /usr/bin/organismSeperateFastaFile.pl --input $inputFasta --outputDir hold

mv hold fastas
