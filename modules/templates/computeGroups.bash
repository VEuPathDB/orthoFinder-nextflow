#!/usr/bin/env bash

set -euo pipefail

ln -s orthofinderSetup/* ./

orthofinder -a 5 -b .

mkdir Results
mv OrthoFinder/Results*/* Results

