#!/usr/bin/env bash

set -euo pipefail

rm -rf filtered
mkdir filtered

seqids="seqIDs.txt"

grep '^>' $coreSequences \
  | sed 's/^>//' \
  | cut -d' ' -f1 \
  > "\$seqids"

for f in OG*.fasta; do
    [ -f "\$f" ] || continue

    SEQ_COUNT=\$(grep ">" \$f | wc -l)

    if [ "\$SEQ_COUNT" -lt 3 ]; then
        # Too few sequences, skip
        continue
    elif [ "\$SEQ_COUNT" -lt 1000 ]; then
        # Small enough — use the group as-is (includes core + peripheral)
        cp \$f filtered/\$f
    else
        # Too large — filter down to core sequences only
        outfasta="\${f}.coreFiltered"

        samtools faidx \$f
        samtools faidx -r \$seqids \$f > \$outfasta

        FILTERED_COUNT=\$(grep ">" \$outfasta | wc -l)
        if [ "\$FILTERED_COUNT" -ge 3 ] && [ "\$FILTERED_COUNT" -lt 1000 ]; then
            cp \$outfasta filtered/\$f
        fi

        rm -f \$outfasta \${f}.fai
    fi
done

rm -f seqIDs.txt
