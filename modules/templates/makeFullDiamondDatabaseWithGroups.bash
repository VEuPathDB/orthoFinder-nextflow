#!/usr/bin/env bash

set -euo pipefail

fixGroupFileIds.py --require-full-coverage $fullProteome $fullGroupFile
createDiamondDatabaseWithGroups.pl --groups fixedGroupFile.txt --proteome $fullProteome
diamond makedb --in fastaWithGroups.fasta --db ortho${buildVersion}db.dmnd
