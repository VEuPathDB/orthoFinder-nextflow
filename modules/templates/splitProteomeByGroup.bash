#!/usr/bin/env bash

set -euo pipefail

if [ -f "/cache/previousFastas/OG0000000.fasta" ]; then
  perl /usr/bin/retainOutdatedOrganisms.pl $outdated $proteome newProteome
  perl /usr/bin/splitProteomeByGroup.pl --groups $groups --proteome newProteome
else 
  perl /usr/bin/splitProteomeByGroup.pl --groups $groups --proteome $proteome
fi
