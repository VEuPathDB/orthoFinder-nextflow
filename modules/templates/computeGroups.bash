#!/usr/bin/env bash

set -euo pipefail

orthofinder -b $diamondResultsDir

rm **/*.txt.gz
rm **/*.txt
rm **/*.fa


