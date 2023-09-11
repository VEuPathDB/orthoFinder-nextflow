#!/usr/bin/env bash

set -euo pipefail

diamond makedb --in $bestRepsFasta --db newdb
diamond blastp \
  -d newdb.dmnd \
  -q $bestRepsFasta \
  -o ${bestRepsFasta}.out \
  -f 6 qseqid qlen sseqid slen qstart qend sstart send evalue bitscore length nident pident positive qframe qstrand gaps qseq \
  --comp-based-stats 0 \
  --no-self-hits \
  $blastArgs

