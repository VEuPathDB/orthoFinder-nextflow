#!/usr/bin/env bash

set -euo pipefail

touch fullProteome.fasta
cat 1.fasta >> fullProteome.fasta
echo "" >> fullProteome.fasta
cat 2.fasta >> fullProteome.fasta
