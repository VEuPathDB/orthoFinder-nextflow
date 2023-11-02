#!/usr/bin/env bash

set -euo pipefail
#TODO remove this
PATH=/home/jbrestel/project_home/orthoFinder/bin:$PATH

getPeripheralResultsToBestRep.pl --similarity $similarityResults \
				 --group $groupAssignments
