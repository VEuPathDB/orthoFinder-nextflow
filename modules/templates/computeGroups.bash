#!/usr/bin/env bash

set -euo pipefail

orthofinder -a 5 -b .

rm *.txt.gz
rm *.fa

mkdir Results
mv OrthoFinder/Results*/* Results

