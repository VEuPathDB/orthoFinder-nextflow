#!/usr/bin/env bash

set -euo pipefail

speciesMappingPath=$speciesMapping;
sequenceMappingPath=$sequenceMapping;

speciesMappingBase=\${speciesMappingPath##*/}
sequenceMappingBase=\${sequenceMappingPath##*/}


checkSequenceOrderForOrganisms.pl --outdated $outdatedOrganisms \
    --cachedSpeciesMapping $previousDiamondCacheDirectory/\$speciesMappingBase \
    --cachedSequenceMapping $previousDiamondCacheDirectory/\$sequenceMappingBase \
    --newSpeciesMapping $speciesMapping \
    --newSequenceMapping $sequenceMapping \
    --output 'full_outdated.txt'
