#!/usr/bin/env bash

set -euo pipefail

grep "diamond blastp" $commandFile > hold.txt

perl /usr/bin/filterBlastCommands.pl --input hold.txt --outputDir .
