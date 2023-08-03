#!/usr/bin/env bash

set -euo pipefail

perl /usr/bin/removeOutdatedBlasts.pl $outdated
cat $outdated > cleaned.txt
