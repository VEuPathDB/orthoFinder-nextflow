#!/usr/bin/env bash

set -euo pipefail

filterResidualSimilaritiesByBestRepresentative.pl --bestReps $bestReps --singletons $singletons --blastResults $allSimilarities
