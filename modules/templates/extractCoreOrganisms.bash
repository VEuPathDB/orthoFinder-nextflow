#!/usr/bin/env bash

set -euo pipefail

cut -d: -f2 $coreSpeciesIds | sed 's/^ //' | cut -d. -f1 > coreOrganisms.txt
