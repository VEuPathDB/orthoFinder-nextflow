#!/usr/bin/env bash

set -euo pipefail

orthofinder -b .

rm *.txt.gz
rm *.fa

mv OrthoFinder/Results* .

