#!/usr/bin/env bash

set -euo pipefail

orthofinder -b . -a 1

rm *.txt.gz
rm *.txt
rm *.fa

mv OrthoFinder/**/* .
rm -rf OrthoFinder
