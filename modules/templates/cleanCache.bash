#!/usr/bin/env bash

set -euo pipefail

if [ -f "/cache/previousFastas/OG0000000.fasta" ]; then
    cat /cache/previousFastas/* > oldProteome
    perl /usr/bin/removeOutdatedOrganisms.pl $updateList oldProteome cleanedProteome
    perl /usr/bin/splitProteomeByGroup.pl --groups /cache/GroupsFile.txt --proteome cleanedProteome
    rm -rf /cache/previousFastas/*
    cp *.fasta /cache/previousFastas/
    for f in /cache/previousResults/*; do perl /usr/bin/removeOutdatedResults.pl $updateList "\$f" .; done    
    touch done.txt
else
    touch done.txt
fi


