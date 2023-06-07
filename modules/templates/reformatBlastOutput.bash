#!/usr/bin/env bash

set -euo pipefail

perl /usr/bin/reformatBlastOutput.pl --blastOutput $blastOutput --sequenceIds $sequenceIDs --output reformattedBlast.tsv 
