#!/usr/bin/env bash

set -euo pipefail

for f in *.tsv; do calculateGroupResults.pl --bestRepResults \$f; done
