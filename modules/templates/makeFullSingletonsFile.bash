#!/usr/bin/env bash

set -euo pipefail

LASTGROUP=\$(cut -f1 $orthogroups | tail -n1) 

makeFullSingletonsFile.pl --lastGroup \$LASTGROUP \
			  --buildVersion $buildVersion \
			  --fileSuffix "singletons" \
			  --outputFile singletonsFull.dat

LASTSINGLETONSGROUP=\$(cut -f1 singletonsFull.dat | tail -n1) 

addTranslatedMissingGroupMembers.pl --lastGroup \$LASTSINGLETONSGROUP \
				    --sequenceMapping $sequenceMapping \
				    --missingGroups $missingGroups \
				    --singletonsFile singletonsFull.dat \
				    --version $buildVersion \
				    --groupMapping $orthogroups
