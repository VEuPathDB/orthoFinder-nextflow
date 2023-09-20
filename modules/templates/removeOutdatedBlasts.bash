#!/usr/bin/env bash

set -euo pipefail

# pass the location of previous blasts dir to this script

removeOutdatedBlasts.pl $outdated $previousBlastDir
