#!/usr/bin/env bash

set -euo pipefail

tail -n +1 *.sim > combined.sim

findBestRepresentatives.pl --groupFile combined.sim >> best_representative.txt
