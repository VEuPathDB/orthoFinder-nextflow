#!/usr/bin/env bash

set -euo pipefail

for f in *.fasta; do
    [ -f "\$f" ] || continue

    SEQ_COUNT=\$(grep ">" \$f | wc -l)
    if [ "\$SEQ_COUNT" -ge 3 ]; then
        mafft --retree 1 --maxiterate 0 --anysymbol \$f | fasttree -mlnni 4 > \${f}.tree
    fi

done
