#!/usr/bin/env bash

set -euo pipefail

for f in *.singletons; do makeFullSingletonsFile.pl --singletons "\$f"; done
