#!/usr/bin/env bash

set -euo pipefail

orthogroupStatistics.pl --groupsFile Results/Orthogroups/Orthogroups.tsv --output groupStats.tsv
