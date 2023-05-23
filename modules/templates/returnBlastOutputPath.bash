#!/usr/bin/env bash

set -euo pipefail

echo "${params.outputDir}/blastOutput/" > output.txt

export blastOutputPath=\$(cat output.txt)
