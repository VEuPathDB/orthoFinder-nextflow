#!/usr/bin/env bash

set -euo pipefail

LASTGROUP=\$(cut -f2 $orthogroups | tail -n1) 

makeFullSingletonsFile.pl --lastGroup \$LASTGROUP \
			  --buildVersion $buildVersion \
			  --fileSuffix "singletons" \
			  --outputFile singletonsFull.dat
