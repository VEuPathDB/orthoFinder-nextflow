#!/usr/bin/env bash

set -euo pipefail

reformatGroupsFile.pl --groupFile $groupsFile --buildVersion $buildVersion --coreOrResidual $coreOrResidual

cat $translatedSingletons >> reformattedGroups.txt
