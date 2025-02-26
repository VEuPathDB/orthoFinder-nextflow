#!/usr/bin/env bash

set -euo pipefail

previousGroups.pl --oldGroupsFile $oldGroupsFile \
		  --newGroupsFile $newGroupsFile \
		  --outputFile previousGroups.txt
