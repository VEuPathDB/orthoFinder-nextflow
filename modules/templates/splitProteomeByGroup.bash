#!/usr/bin/env bash

set -euo pipefail

perl /usr/bin/splitProteomeByGroup.pl --groups $groups --proteome $proteome 
