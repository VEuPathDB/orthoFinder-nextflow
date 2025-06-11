#!/usr/bin/env bash

set -euo pipefail

for file in *.sim; do echo "> \$file <" >> combined_output.txt; cat "\$file" >> combined_output.txt; done

translateBlastResults.pl --blastFile combined_output.txt --translateFile $translateFile --outputFile translatedGroupBlastFile.tsv

filterSimilaritiesByBestRepresentative.pl --blastFile translatedGroupBlastFile.tsv --bestReps $bestReps --outputFile intraResidualGroupBlastFile.tsv
