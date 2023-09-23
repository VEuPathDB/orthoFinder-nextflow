#!/usr/bin/env bash

set -euo pipefail

ln -s $fastas/* ./

mkdir orthofinderSetup

orthofinder -f . -op

mv OrthoFinder/**/WorkingDirectory/*.txt ./orthofinderSetup/
mv OrthoFinder/**/WorkingDirectory/*.fa ./orthofinderSetup/
mv OrthoFinder/**/WorkingDirectory/*.dmnd ./orthofinderSetup/

cp orthofinderSetup/S*.txt ./
