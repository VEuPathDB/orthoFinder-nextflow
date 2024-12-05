#!/usr/bin/env bash

set -euo pipefail

makePeripheralOrthologGroupDiamondFiles.pl --blastFile $blastFile \
	                                   --groups $orthologs
