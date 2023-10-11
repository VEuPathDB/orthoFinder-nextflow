#!/usr/bin/env bash

set -euo pipefail

removeOutdatedOrganisms.pl $outdatedOrganisms $peripheralDiamondCache
