#!/usr/bin/env bash

set -euo pipefail

mkdir cleanedCache
cp -r $peripheralDiamondCache cleanedCache

removeOutdatedOrganisms.pl $outdatedOrganisms cleanedCache
