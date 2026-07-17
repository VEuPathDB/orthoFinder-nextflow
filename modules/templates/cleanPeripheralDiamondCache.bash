#!/usr/bin/env bash

set -euo pipefail

mkdir cleanedCache

# Nextflow stages an external (non-process-produced) directory input like this as a
# symlink to the real directory. `cp -r src dest/` (dest already existing) copies that
# symlink itself as a nested entry rather than the real directory's contents, leaving
# cleanedCache with no .out files at its top level -- so use the trailing-dot form to
# copy contents through the symlink instead.
cp -r $peripheralDiamondCache/. cleanedCache/

removeOutdatedOrganisms.pl $outdatedOrganisms cleanedCache
