#!/usr/bin/env bash

set -euo pipefail

makeOrthologGroupDiamondFiles.pl --blastFile $blastFile \
				 --groups $orthologs
