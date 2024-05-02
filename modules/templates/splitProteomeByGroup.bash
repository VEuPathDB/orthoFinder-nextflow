#!/usr/bin/env bash

set -euo pipefail

splitProteomeByGroup.pl --groups $groups --proteome $proteome

rm *.tmp
rm *.fasta.fai
