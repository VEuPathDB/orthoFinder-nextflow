#!/usr/bin/env bash

set -euo pipefail

translateGroupsFile.pl --groupsFile $orthoGroupsFile \
		       --sequenceFile $sequenceMapping \
		       --singletonsFile Singletons.dat \
		       --output translatedGroups.txt 
makeOrthogroupSpecificFiles.pl --groupsFile translatedGroups.txt
