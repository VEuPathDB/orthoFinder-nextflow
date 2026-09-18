#!/usr/bin/env bash

set -euo pipefail

mergeBestReps.pl --cachedCoreBestReps $cachedCoreBestReps \
                 --cachedResidualBestReps $cachedResidualBestReps \
                 --touchedBestReps $touchedBestReps \
                 --touchedGroups $touchedGroups \
                 --outputCore mergedCoreBestReps.txt \
                 --outputResidual mergedResidualBestReps.txt
