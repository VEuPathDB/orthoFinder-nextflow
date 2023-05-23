#!/usr/bin/env bash

set -euo pipefail

perl /usr/bin/retrieveFilePaths.pl --input $filteredCommand --outputDir .

export dataPath=\$(cat dataPath.txt)
export queryPath=\$(cat queryPath.txt)
export outputPath=\$(cat outputPath.txt)
