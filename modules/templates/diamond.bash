#!/usr/bin/env bash

set -euo pipefail

perl /usr/bin/orthoFinderBlast.pl --database ${pair[0]} --query ${pair[1]} --sequenceIDs SequenceIDs.txt --speciesIDs SpeciesIDs.txt

cp Blast*.txt.gz hold.txt.gz
gunzip hold.txt.gz
rm *.dmnd
rm -rf previousBlasts

echo "Testing"
ls /previousBlasts
