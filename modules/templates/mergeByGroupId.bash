#!/usr/bin/env bash

set -euo pipefail

mergeByGroupId.pl --cached $cached \
                  --touchedGroups $touchedGroups \
                  --fresh $fresh \
                  --output merged.txt
