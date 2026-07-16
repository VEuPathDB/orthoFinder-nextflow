#!/usr/bin/env bash

set -euo pipefail

# OrthoFinder inconsistently substitutes ':' <-> '_' in sequence IDs; reconcile
# every ID in the groups file against the real (pre-OrthoFinder) residual proteome
# headers here so downstream consumers never see a mismatched ID.
fixGroupFileIds.py $residualFasta $groupsFile
mv fixedGroupFile.txt holdReformat.txt

sed 's/^OG/OGR${buildVersion}r${residualBuildVersion}_/g' holdReformat.txt > reformattedGroups.txt

echo "$residualBuildVersion" > buildVersion.txt
