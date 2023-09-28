#!/usr/bin/env bash

set -euo pipefail
 
diamond blastp \
  -d $database \
  -q $fasta \
  -o diamondSimilarity.out \
  -f 6 qseqid qlen sseqid slen qstart qend sstart send evalue bitscore length nident pident positive qframe qstrand gaps qseq \
  --comp-based-stats 0 \
  $diamondArgs
