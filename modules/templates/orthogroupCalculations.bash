#!/usr/bin/env bash

set -euo pipefail

for f in *.dat; do orthogroupCalculations.pl --groupFile "\$f"; done


