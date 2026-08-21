#!/usr/bin/env bash

set -euo pipefail

# Output keeps the exact same "<groupID>.sim" filename as the input --
# downstream calculateGroupStatistics.pl looks up files by that exact name.
# Safe: filtered files are collected in their own separate channel/work dirs,
# never mixed in the same directory as the unfiltered originals.
outputName=\$(basename $simFile)

filterSimByCoreOrganisms.pl --simFile $simFile \
                            --proteinToOrganism $proteinToOrganism \
                            --coreOrganisms $coreOrganisms \
                            --output \$outputName
