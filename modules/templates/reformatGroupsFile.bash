#!/usr/bin/env bash

set -euo pipefail

reformatGroupsFile.pl --groupFile $groupsFile --buildVersion $buildVersion

cat $translatedSingletons >> reformattedGroups.txt

# OrthoFinder inconsistently substitutes ':' <-> '_' in sequence IDs; reconcile
# every ID in the groups file against the real (pre-OrthoFinder) proteome headers
# here so downstream consumers never see a mismatched ID.
fixGroupFileIds.py --require-full-coverage $proteomes/*.fasta reformattedGroups.txt
mv fixedGroupFile.txt reformattedGroups.txt

echo "$buildVersion" > buildVersion.txt

if [ "$coreOrResidual" = "residual" ]; then
    mv reformattedGroups.txt holdReformat.txt
    sed 's/^OG/OGR/g' holdReformat.txt > reformattedGroups.txt
fi

