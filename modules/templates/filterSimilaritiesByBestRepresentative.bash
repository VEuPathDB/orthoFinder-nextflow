#!/usr/bin/env bash

set -euo pipefail

filterSimilaritiesByBestRepresentative.pl --bestReps $bestReps --singletons $singletons
