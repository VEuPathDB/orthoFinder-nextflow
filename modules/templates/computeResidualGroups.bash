#!/usr/bin/env bash

set -euo pipefail

ln -s $orthofinderWorkingDir/* ./

orthofinder -a 5 -b . -og

ln -s OrthoFinder/Results* ./Results
