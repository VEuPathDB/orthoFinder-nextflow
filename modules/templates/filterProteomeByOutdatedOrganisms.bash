#!/usr/bin/env bash

set -euo pipefail

filterProteomeByOutdatedOrganisms.pl --proteome $previousFullProteome \
                                     --proteinToOrganism $proteinToOrganism \
                                     --outdatedOrganisms $outdatedOrganisms \
                                     --output filteredPreviousProteome.fasta
