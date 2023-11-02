#!/usr/bin/env bash

set -euo pipefail


# TODO:  this looks suspicious
if [ -f "/cache/previousFastas/OG0000000.fasta" ]; then
  retainOutdatedOrganisms.pl $outdated $proteome newProteome
  splitProteomeByGroup.pl --groups $groups --proteome newProteome
else 
  splitProteomeByGroup.pl --groups $groups --proteome $proteome
fi
