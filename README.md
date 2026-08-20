# orthoFinder-nextflow

A Nextflow DSL2 pipeline that builds and incrementally updates ortholog groups across VEuPathDB organisms using OrthoFinder, Diamond, and Mash.

## Overview

VEuPathDB computes ortholog groups across the proteomes of all organisms in its databases so that orthology relationships can be browsed and queried on the sites. Because the full set of organisms is large and grows over time, this pipeline splits that computation into stages so that new or updated ("peripheral") organisms can be incorporated without rerunning the expensive all-vs-all comparison for the full ("core") organism set each time:

- **core** — runs OrthoFinder (Diamond all-vs-all similarity search plus hierarchical orthogroup inference) over the core set of reference proteomes to build the baseline ortholog groups, best representative sequences, and group statistics. A Diamond similarity cache lets subsequent runs reuse previously computed comparisons for organisms that haven't changed.
- **peripheral** — compares peripheral (new/updated) organism proteomes against the core best representatives and assigns their sequences to existing core orthogroups; sequences that can't be confidently assigned are split out as "residual" for further clustering.
- **residual** — runs a full OrthoFinder clustering pass over the residual sequences left over from the peripheral stage to form new orthogroups from proteins that didn't fit into the core groups.
- **postResidual** — post-processes the residual orthogroups (reformatting, best-representative selection, group statistics) the same way the core stage does.
- **postProcessing** — merges the core and residual best representatives and group files into a single combined orthology result, builds a full Diamond database over the merged groups, compares against a previous groups release, and builds gene trees (MAFFT + FastTree) for the resulting orthogroups.

## Requirements

- [Nextflow](https://www.nextflow.io/) (DSL2)
- [Docker](https://www.docker.com/) (enabled by default in every profile; the pipeline's image is built from `davidemms/orthofinder:2.5.5.2` with Diamond, Mash, MAFFT, and FastTree added)

## Usage

Each stage is a separate `-entry` point with its own `-profile` of the same name. Stages are normally run in sequence, since each consumes the output of the one before it.

```bash
# core (also the default entry point)
nextflow run VEuPathDB/orthoFinder-nextflow -r main -entry coreEntry -profile core -resume -C <config>

# peripheral
nextflow run VEuPathDB/orthoFinder-nextflow -r main -entry peripheralEntry -profile peripheral -resume -C <config>

# residual
nextflow run VEuPathDB/orthoFinder-nextflow -r main -entry residualEntry -profile residual -resume -C <config>

# postResidual
nextflow run VEuPathDB/orthoFinder-nextflow -r main -entry postResidualEntry -profile postResidual -resume -C <config>

# postProcessing
nextflow run VEuPathDB/orthoFinder-nextflow -r main -entry postProcessingEntry -profile postProcessing -resume -C <config>
```

### Entry points

| Entry | Description |
|---|---|
| `coreEntry` (default) | Runs OrthoFinder over `params.proteomes` to produce the core ortholog groups |
| `peripheralEntry` | Assigns `params.peripheralProteomes` to the core groups produced by `coreEntry` |
| `residualEntry` | Clusters the residual sequences produced by `peripheralEntry` into new orthogroups |
| `postResidualEntry` | Post-processes the residual orthogroups from `residualEntry` |
| `postProcessingEntry` | Merges core and residual results into the final combined orthology output |

## Key parameters

| Parameter | Used by | Description |
|---|---|---|
| `outputDir` | all | Directory the stage's outputs are published to |
| `buildVersion` | core, peripheral, postResidual, postProcessing | Build version number tagged into output files |
| `proteomes` | core | Compressed archive of core organism proteome FASTA files |
| `diamondSimilarityCache` | core | Directory of cached Diamond similarity results, reused for organisms that haven't changed |
| `outdatedOrganisms` | core, peripheral | File listing organism abbreviations whose cached results should not be reused |
| `orthoFinderDiamondOutputFields` | core, peripheral, residual | Diamond output column spec passed to OrthoFinder's search step |
| `coreProteomes` | peripheral | Core proteome archive (same input as `coreEntry`'s `proteomes`) |
| `peripheralProteomes` | peripheral | Compressed archive of new/updated organism proteome FASTA files |
| `coreGroupsFile` | peripheral | Reformatted groups file produced by `coreEntry` |
| `coreGroupSimilarities` | peripheral | Per-group Diamond similarity files produced by `coreEntry` |
| `peripheralDiamondCache` | peripheral | Cache of previously computed peripheral-to-core Diamond comparisons |
| `residualFastaDir` | residual | Compressed residual FASTA directory produced by `peripheralEntry` |
| `groupsFile` / `speciesMapping` / `sequenceMapping` / `diamondResultsFile` | postResidual | OrthoFinder outputs from `residualEntry` (orthogroups, species/sequence ID maps, similarity results) |
| `residualBuildVersion` | postResidual | Build version tag applied to residual group output |
| `residualFasta` / `residualBestRepsFasta` / `coreBestRepsFasta` | postProcessing | Best-representative FASTAs from the residual and core stages |
| `coreAndPeripheralGroups` / `coreAndPeripheralProteome` | postProcessing | Combined groups file and proteome from `peripheralEntry` |
| `residualGroups` | postProcessing | Reformatted residual groups file from `postResidualEntry` |
| `oldGroupsFile` | postProcessing | Previous release's groups file, used to compare group membership across releases |
| `coreGroupFastas` / `residualGroupFastas` | postProcessing | Per-group FASTA directories for core and residual groups |

## Output

Each stage publishes to its own `outputDir` (`coreOutput`, `peripheralOutput`, `residualOutput`, `postResidualOutput`, `postProcessingOutput` by default):

- **core / residual** — OrthoFinder `Results` directory, `Orthogroups.txt`, species/sequence ID mappings, reformatted groups files, best-representative FASTAs, per-group Diamond similarity files, and group statistics
- **peripheral** — updated groups file combining core and peripheral assignments, residual/peripheral FASTAs, organism assignment counts, and the combined proteome
- **postResidual** — reformatted residual groups file, residual best-representative FASTA, and residual group statistics
- **postProcessing** — the final merged groups file and best-representative FASTA combining core and residual orthogroups, a full Diamond database over the merged groups, a comparison against the previous groups release, and gene trees per orthogroup
