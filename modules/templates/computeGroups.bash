#!/usr/bin/env bash

set -euo pipefail

orthofinder -b .

rm *.txt.gz
rm *.fa

mkdir Results
mv OrthoFinder/Results*/* Results

