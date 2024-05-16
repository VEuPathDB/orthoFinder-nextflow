#!/usr/bin/env bash

set -euo pipefail

mv $groupsFile holdReformat.txt
sed 's/^OG/OGR${buildVersion}_/g' holdReformat.txt > reformattedGroups.txt


