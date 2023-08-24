#!/usr/bin/env bash

set -euo pipefail

touch fullProteome.fasta
cat $coreProteome >> fullProteome.fasta
cat $peripheralProteome >> fullProteome.fasta
