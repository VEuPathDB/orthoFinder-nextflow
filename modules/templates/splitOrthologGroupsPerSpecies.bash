#!/usr/bin/env bash

set -euo pipefail



splitOrthologGroupsPerSpecies --species_mapping $speciesMapping \
    --sequence_mapping $sequenceMapping \
    --ortholog_groups $orthologgroups \
    --species $species \
    --output_file_suffix orthologs \
    --singletons_file "${species}.singletons" \
    --build_version $params.buildVersion
