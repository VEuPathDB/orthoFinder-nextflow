#!/usr/bin/env bash

set -euo pipefail
assignGroupsForPeripherals.pl --result $sortedResults --output groups.txt
