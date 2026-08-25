#!/usr/bin/env bash

set -euo pipefail

# Split "GROUPID\tSEQID" rows by group type -- core/peripheral (OG) stats and
# blast values must never see residual (OGR) rows and vice versa; each group
# type has its own separate cached file and its own separate DB loader.
grep '^OGR' $touchedBestReps > touchedResidualBestReps.txt || true
grep -v '^OGR' $touchedBestReps > touchedCoreBestReps.txt || true
