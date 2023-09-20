#!/usr/bin/env bash

set -euo pipefail

orthofinder -f $fastas -op

for f in input/OrthoFinder/**/WorkingDirectory/*.txt; do mv "\$f" .; done
for f in input/OrthoFinder/**/WorkingDirectory/*.fa; do mv "\$f" .; done
for f in input/OrthoFinder/**/WorkingDirectory/*.dmnd; do mv "\$f" .; done
