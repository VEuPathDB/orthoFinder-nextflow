#!/usr/bin/env bash

set -euo pipefail

mkdir diamondResults
mv *.txt.gz diamondResults
perl /usr/bin/renameDiamondFiles.pl SpeciesIDs.txt SequenceIDs.txt ./diamondResults
mv diamondResults/*.txt.gz .
