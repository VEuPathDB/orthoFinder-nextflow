#!/usr/bin/env bash

set -euo pipefail

echo "${params.outputDir}" > output.txt

export blastOutputPath=\$(cat output.txt)
