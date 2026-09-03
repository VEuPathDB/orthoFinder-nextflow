#!/usr/bin/env bash

set -euo pipefail

filterProteomeByOutdatedOrganisms.pl --proteome $proteome \
                                     --proteinToOrganism $proteinToOrganism \
                                     --outdatedOrganisms $outdatedOrganisms \
                                     --output filteredPreviousProteome.fasta
