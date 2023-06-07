#!/usr/bin/env bash

set -euo pipefail

perl /usr/bin/orthoFinderBlast.pl --database ${pair[0]} --query ${pair[1]}

cp Blast*.txt.gz hold.txt.gz
gunzip hold.txt.gz
rm *.dmnd
