---
layout: default
title: MLP (Microbial Load)
parent: Modules
nav_order: 11
---

# MLP — Microbial Load Prediction
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Overview

The Microbial Load Predictor (MLP) predicts absolute microbial load from MetaPhlAn relative abundance profiles using a machine-learning model trained on faecal metagenomes.

| Attribute | Value |
|-----------|-------|
| Tool | [MLP R package](https://github.com/grp-bork/microbial_load_predictor) |
| Language | R 4.3.1 |
| Training model | `metaphlan4.mpa_vJan25_CHOCOPhlAnSGB_202503` |
| Training data | `galaxy` |
| Config flag | `mlp` (default: `false`) |
| Requires | `metaphlan=true` |
| Rules | `install_mlp_package`, `mlp` |
| Rule file | `Workflow/rules/mlp.smk` |

---

## Enable

```bash
snakemake --use-conda --cores 8 \
    --config metaphlan=true mlp=true
```

{: .warning }
MLP was trained on **faecal samples**. It may produce unreliable results for other sample types (saliva, skin, environmental, etc.).

---

## Rules

### `install_mlp_package`

Installs the MLP R package from GitHub on first run. Verifies that model files exist in the package's `extdata` directory.

Output: `Data/MLP/.mlp_package_installed` (marker file)

### `mlp`

Runs the MLP prediction using the R script `Workflow/scripts/mlp.R`.

**Input:** `Data/MetaPhlAn/table/abundance_species.txt` (species-level abundance table)

**Output:**
| File | Description |
|------|-------------|
| `Data/MLP/load.tsv` | Predicted absolute microbial load per sample |
| `Data/MLP/qmp.tsv` | QMP (Quantitative Microbial Profiling) values |

---

## R Script Workflow

`Workflow/scripts/mlp.R`:

1. Loads the MLP R package
2. Reads the species-level MetaPhlAn profile
3. Transposes the matrix so samples are rows and species are columns
4. Calls `MLP()` with:
   - `profiler = "metaphlan4.mpa_vJan25_CHOCOPhlAnSGB_202503"`
   - `training_data = "galaxy"`
5. Writes `load.tsv` and `qmp.tsv`

---

## Output Interpretation

- **`load.tsv`** — Predicted 16S rRNA gene copies per gram (or per mL) of sample. Higher values indicate denser microbial communities.
- **`qmp.tsv`** — Quantitative Microbial Profiling values: relative abundances corrected by predicted load, giving estimates of absolute species abundances.

QMP values are particularly useful for longitudinal studies and comparisons across samples with very different microbial densities.

---

## R Dependencies

The MLP Conda environment (`Workflow/envs/mlp.yaml`) includes:

- R 4.3.1
- tidyverse
- xgboost
- caret
- randomForest
- glmnet

A post-deploy script (`Workflow/envs/mlp.post-deploy.sh`) installs the MLP package from GitHub after the Conda environment is built.
