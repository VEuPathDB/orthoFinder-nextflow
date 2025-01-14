#!/usr/bin/env bash

set -euo pipefail

translateBestRepsFile.pl --bestReps $bestReps \
                         --sequenceIds $sequenceMapping \
			 --outputFile bestReps.txt

