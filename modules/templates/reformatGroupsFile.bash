#!/usr/bin/env bash

set -euo pipefail

reformatGroupsFile.pl --groupFile $groupsFile --buildVersion $buildVersion

cat $translatedSingletons >> reformattedGroups.txt
