#!/usr/bin/env bash

set -euo pipefail

assignToStableGroupsOrResidual.pl --result $diamondInput \
                                  --output groups.txt \
                                  --groupFile $stableGroups
