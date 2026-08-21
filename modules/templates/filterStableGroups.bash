#!/usr/bin/env bash

set -euo pipefail

filterStableGroups.pl --fullGroupFile $fullGroupFile \
                      --residualGroupFile $residualGroupFile \
                      --proteinToOrganism $proteinToOrganism \
                      --outdatedOrganisms $outdatedOrganisms \
                      --output stableGroups.txt
