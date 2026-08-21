#!/usr/bin/env bash

set -euo pipefail

mergeAssignedIntoStableGroups.pl --stableGroups $stableGroups \
                                 --assignments $assignments \
                                 --output updatedStableGroups.txt
