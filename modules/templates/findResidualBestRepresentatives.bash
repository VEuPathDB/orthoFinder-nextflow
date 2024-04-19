#!/usr/bin/env bash

set -euo pipefail

tail -n +1 *.sim > combined.sim

findResidualBestRepresentatives.pl \
    --groupFile combined.sim >> best_representative.txt
