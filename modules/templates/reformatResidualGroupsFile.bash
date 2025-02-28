#!/usr/bin/env bash

set -euo pipefail

mv $groupsFile holdReformat.txt
sed 's/^OG/OGR${buildVersion}r${residualBuildVersion}_/g' holdReformat.txt > reformattedGroups.txt


