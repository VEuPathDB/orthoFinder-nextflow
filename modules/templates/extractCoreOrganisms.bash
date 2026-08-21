#!/usr/bin/env bash

set -euo pipefail

cut -d: -f2 $coreSpeciesIds | sed -e 's/\.fasta//' -e 's/^ //' > coreOrganisms.txt
