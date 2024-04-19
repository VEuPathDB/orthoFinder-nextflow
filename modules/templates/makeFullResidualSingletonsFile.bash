#!/usr/bin/env bash

set -euo pipefail

makeFullResidualSingletonsFile.pl --buildVersion $buildVersion \
			          --fileSuffix "singletons" \
        			  --outputFile singletonsFull.dat
