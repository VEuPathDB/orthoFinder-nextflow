#!/usr/bin/env bash

set -euo pipefail

for f in *.fasta;
do
    SEQ_COUNT=\$(grep ">" \$f | wc -l) \
        && echo "\$f" \
	&& echo "\$SEQ_COUNT"
    if [ "\$SEQ_COUNT" -ge 3 ]; then
	mafft --auto --anysymbol \$f | fasttree -mlnni 4 > \$f.tree
    else
	touch \$f.tree
    fi	
done
