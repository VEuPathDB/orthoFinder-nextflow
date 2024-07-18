#!/usr/bin/env bash

set -euo pipefail

for f in *.fasta;

do

    SEQ_COUNT=\$(grep ">" \$f | wc -l) 
    if [ "\$SEQ_COUNT" -ge 3 ] && [ "\$SEQ_COUNT" -le 10000 ]; then
	mafft --auto --anysymbol \$f | fasttree -mlnni 4 > \$f.tree
    fi	

done
