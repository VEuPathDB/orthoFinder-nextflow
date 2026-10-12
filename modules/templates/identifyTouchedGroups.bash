#!/usr/bin/env bash

set -euo pipefail

cut -f 2 $newAssignments | sort -u > gainedGroups.txt

# droppedMemberGroups lists every group that lost >=1 member this run, regardless of how
# many members it has left -- including one that dropped below 2 and no longer exists as
# a group at all. updatedStableGroups is this run's comprehensive, current group-membership
# file, so a dropped group still appears there under its own ID iff it's still valid.
# Without this filter, a dissolved group still ends up in touchedGroups.txt, and
# computeGroupIdRenameMap (downstream) computes a rename for it anyway -- a rename-map
# entry with no group left anywhere to apply it to. A gained-member group needs no such
# check: it's always an existing stable group a sequence just matched into, never one that
# could have dissolved by gaining a member.
cut -d: -f1 $updatedStableGroups | sort -u > currentGroupIds.txt
comm -12 <(sort -u $droppedMemberGroups) currentGroupIds.txt > stillValidDroppedGroups.txt

cat stillValidDroppedGroups.txt gainedGroups.txt | sort -u > touchedGroups.txt
