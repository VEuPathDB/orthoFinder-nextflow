#!/usr/bin/env bash

set -euo pipefail

mkdir -p touchedGroupFastas

splitTouchedGroupFastas.pl --groupFile $groupFile \
                           --touchedGroups $touchedGroups \
                           --proteome $currentProteome \
                           --proteome $previousFullProteome \
                           --outputDir touchedGroupFastas
