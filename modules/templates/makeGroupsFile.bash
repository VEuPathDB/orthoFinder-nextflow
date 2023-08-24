#!/usr/bin/env bash

set -euo pipefail

perl /usr/bin/makeGroupsFile.pl --coreGroup $coreGroups --peripheralGroup $peripheralGroups --output GroupsFile.txt
