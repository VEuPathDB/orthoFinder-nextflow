#!/usr/bin/env bash

set -euo pipefail

# Output keeps the exact same "<groupID>.sim" filename as the input --
# downstream calculateGroupStatistics.pl looks up files by that exact name.
# Safe: filtered files are collected in their own separate channel/work dirs,
# never mixed in the same directory as the unfiltered originals.
outputName=\$(basename $simFile)

# The staged input is a symlink to the cached original -- copy it aside and
# remove the symlink first, so writing the output under the same name
# doesn't try to overwrite a read-only symlink target.
inputCopy=\$(mktemp)
cp $simFile \$inputCopy
rm -f $simFile

filterSimByCoreOrganisms.pl --simFile \$inputCopy \
                            --proteinToOrganism $proteinToOrganism \
                            --coreOrganisms $coreOrganisms \
                            --output \$outputName
