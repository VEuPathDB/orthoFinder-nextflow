#!/usr/bin/env bash

set -euo pipefail

findMissingSimGroups.pl --groupList $touchedGroups --simDir . --output missingCoreTouchedGroups.txt
