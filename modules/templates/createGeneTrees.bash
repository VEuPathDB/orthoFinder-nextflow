#!/usr/bin/env bash

set -euo pipefail

mafft --auto $fasta | fasttree -mlnni 4 > ${fasta}.tree
