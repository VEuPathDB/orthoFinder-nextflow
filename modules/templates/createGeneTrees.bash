#!/usr/bin/env bash

set -euo pipefail

mafft --auto $fasta > ${fasta}.fas #make multiple alignment, output in aligned Fasta format (defaults)

bmge -i ${fasta}.fas  -t AA -h 1 -g 1 -o ${fasta}.phy #convert to phylip format

fastme -i ${fasta}.phy -p -o ${fasta}.tree #make gene tree, output newick format
