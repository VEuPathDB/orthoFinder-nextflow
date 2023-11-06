#!/usr/bin/env bash

set -euo pipefail

for f in *.singletons; do makeFullSingletonsFile.pl --groups $orthogroups --buildVersion $buildVersion --singletons "\$f"; done
