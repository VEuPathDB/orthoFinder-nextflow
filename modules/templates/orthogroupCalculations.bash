#!/usr/bin/env bash

set -euo pipefail

for f in *.dat; do /usr/bin/orthogroupCalculations.pl --groupFile "\$f"; done


