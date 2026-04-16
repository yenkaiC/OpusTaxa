---
layout: default
title: MetaPhlAn
parent: Modules
nav_order: 4
---

# MetaPhlAn — Taxonomic Profiling
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Overview

MetaPhlAn 4 profiles microbial community composition using clade-specific marker genes. It assigns relative abundances from kingdom level down to species level, and produces bowtie2 alignments that are reused by StrainPhlAn and HUMAnN.

| Attribute | Value |
|-----------|-------|
| Tool | [MetaPhlAn](https://github.com/biobakery/MetaPhlAn) |
| Version | 4.2.4 |
| Database index | `mpa_vJan25_CHOCOPhlAnSGB_202503` |
| Database size | ~34 GB |
| Config flag | `metaphlan` (default: `true`) |
| Rules | `dl_metaphlan_DB`, `metaphlan`, `metaphlan_abundance_table` |
| Rule file | `Workflow/rules/metaphlan.smk` |
| Default threads | 8 |
| Default RAM | 50 GB |
| Default wall time | 12 h |

---

## Enable / Disable

MetaPhlAn is **on by default**. To disable:

```bash
snakemake --config metaphlan=false
```

{: .note }
Disabling MetaPhlAn also disables HUMAnN, MLP, and StrainPhlAn, since they depend on MetaPhlAn profiles.

---

## Rules

### `dl_metaphlan_DB`

Downloads and indexes the MetaPhlAn database on first run. A checkpoint file (`Database/metaphlan/.download_complete`) prevents re-downloading.

- **First-run time:** up to 24 hours (34 GB download + indexing)
- Download on a login node before submitting jobs on HPC

### `metaphlan`

Profiles each sample independently.

**Input:**
- `Data/NoHuman/{sample}_R1_001.fastq.gz`
- `Data/NoHuman/{sample}_R2_001.fastq.gz`
- MetaPhlAn database

**Output:**
| File | Description |
|------|-------------|
| `Data/MetaPhlAn/{sample}/{sample}_profile.txt` | Relative abundance profile (all taxonomic levels) |
| `Data/MetaPhlAn/{sample}/{sample}_bowtie.bz2` | bowtie2 SAM alignment (used by StrainPhlAn and HUMAnN) |

Output type: `rel_ab_w_read_stats` (relative abundances with read statistics).

### `metaphlan_abundance_table`

Merges all per-sample profiles into cohort-level tables.

**Output:**
| File | Description |
|------|-------------|
| `Data/MetaPhlAn/table/abundance_all.txt` | All taxonomic levels merged |
| `Data/MetaPhlAn/table/abundance_species.txt` | Species-level only |

---

## Output Format

Each per-sample profile (`{sample}_profile.txt`) contains:

```
#mpa_vJan25_CHOCOPhlAnSGB_202503
#/path/to/metaphlan ...
#clade_name    clade_taxid    relative_abundance    coverage    estimated_number_of_reads_from_the_clade
k__Bacteria    2              100.0                 ...         ...
p__Firmicutes  1239           45.2                 ...         ...
...
s__Faecalibacterium_prausnitzii   853    12.3    ...    ...
```

The merged table (`abundance_all.txt`) has samples as columns and clades as rows.

---

## Downstream Dependencies

MetaPhlAn outputs are required by:

- **[HUMAnN]({% link modules/humann.md %})** — uses species-level profile to guide functional profiling
- **[MLP]({% link modules/mlp.md %})** — uses species-level abundance table for load prediction
- **[StrainPhlAn]({% link modules/strainphlan.md %})** — uses bowtie2 alignments for strain reconstruction

---

## Thread Configuration

```yaml
threads:
  metaphlan: 8
```
