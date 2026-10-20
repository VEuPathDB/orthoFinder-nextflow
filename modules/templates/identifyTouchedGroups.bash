#!/usr/bin/env bash

set -euo pipefail

cut -f 2 $newAssignments | sort -u > gainedGroups.txt

cat $droppedMemberGroups gainedGroups.txt | sort -u > touchedGroups.txt
