#!/usr/bin/env bash

set -euo pipefail

orthofinder -b .

rm *.txt.gz
rm *.txt
rm *.fa

mv OrthoFinder/**/* .
rm -rf OrthoFinder

