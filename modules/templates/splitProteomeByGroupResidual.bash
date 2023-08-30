#!/usr/bin/env bash

set -euo pipefail

perl /usr/bin/splitProteomeByGroupResidual.pl --groups Results/Orthogroups/Orthogroups.tsv --proteome $proteome
