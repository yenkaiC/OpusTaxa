---
layout: default
title: HUMAnN (Functional Profiling)
parent: Modules
nav_order: 8
---

# HUMAnN — Functional Profiling
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Overview

HUMAnN 3 maps reads to gene families and metabolic pathways, producing quantitative functional profiles for each sample.

| Attribute | Value |
|-----------|-------|
| Tool | [HUMAnN](https://github.com/biobakery/HUMAnN) |
| Version | 3.9 |
| Config flag | `humann` (default: `false`) |
| Requires | `metaphlan=true` |
| Rules | `dl_humann_chocophlan`, `dl_humann_uniref`, `dl_humann_utility`, `humann`, `humann_merge_tables` |
| Rule file | `Workflow/rules/humann.smk` |
| Default threads | 10 |
| Default RAM | 64 GB |
| Default wall time | 23 h |

---

## Enable

```bash
snakemake --use-conda --cores 16 \
    --config metaphlan=true humann=true
```

---

## Required Databases (~52 GB total)

All three components download automatically:

| Database | Size | Purpose |
|----------|------|---------|
| ChocoPhlAn | ~24 GB | Nucleotide gene catalog |
| UniRef90 | ~23 GB | Protein database for translated search |
| Utility mapping | ~5 GB | Pathway maps and gene family mappings |

---

## Rules

### `dl_humann_chocophlan` / `dl_humann_uniref` / `dl_humann_utility`

Download HUMAnN databases. Each is checked independently; only missing databases are downloaded.

### `humann`

Runs the full HUMAnN pipeline per sample.

{: .note }
HUMAnN runs on **forward reads only (R1)**. This avoids read-pairing complications in the translated search step. The MetaPhlAn species profile from the same sample guides the nucleotide alignment phase.

**Input:**
- `Data/NoHuman/{sample}_R1_001.fastq.gz` (forward reads only)
- `Data/MetaPhlAn/{sample}/{sample}_profile.txt` (MetaPhlAn species profile)
- All three HUMAnN databases

**Output:**
| File | Description |
|------|-------------|
| `Data/HUMAnN/genefamilies/{sample}_genefamilies.tsv` | UniRef90 gene families |
| `Data/HUMAnN/pathabundance/{sample}_pathabundance.tsv` | MetaCyc pathway abundances |
| `Data/HUMAnN/pathcoverage/{sample}_pathcoverage.tsv` | Pathway coverage scores |

Configuration: bypasses nucleotide search, uses maximum memory mode.

### `humann_merge_tables`

Joins, normalizes, and splits all sample tables.

**Final outputs (to `Data/HUMAnN/merged/`):**

| File | Description |
|------|-------------|
| `genefamilies_cpm_unstratified.tsv` | Gene families normalized to CPM, unstratified |
| `pathabundance_cpm_unstratified.tsv` | Pathway abundances normalized to CPM, unstratified |
| `pathcoverage_joined_unstratified.tsv` | Pathway coverage, unstratified |

"Unstratified" = community-level totals only (no per-species breakdown).

---

## Output Interpretation

- **Gene families** — UniRef90 clusters with abundance in CPM (counts per million reads)
- **Pathway abundance** — MetaCyc pathway abundance in CPM
- **Pathway coverage** — fraction of a pathway's reactions that are covered (0–1)

High coverage + high abundance = confidently active pathway.

---

## Thread Configuration

```yaml
threads:
  humann: 10
```
