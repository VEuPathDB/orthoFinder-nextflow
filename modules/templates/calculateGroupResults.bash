#!/usr/bin/env bash

set -euo pipefail

if [ "$isResidual" = true ]; then

    for f in *.tsv; do calculateGroupResults.pl --bestRepResults \$f --evalueColumn $evalueColumn --isResidual true; done
    
else

    for f in *.tsv; do calculateGroupResults.pl --bestRepResults \$f --evalueColumn $evalueColumn; done
    
fi





