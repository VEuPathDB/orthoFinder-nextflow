#!/usr/bin/env bash

set -euo pipefail

diamond makedb --in $groupFasta --db newdb
diamond blastp \
	-d newdb.dmnd \
	-q $groupFasta \
	-o ${groupFasta}.out \
	-f 6 qseqid qlen sseqid slen qstart qend sstart send evalue bitscore length nident pident positive qframe qstrand gaps qseq \
	--comp-based-stats 0 \
	$blastArgs


