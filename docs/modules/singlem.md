---
layout: default
title: SingleM
parent: Modules
nav_order: 5
---

# SingleM — Marker Gene Profiling
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Overview

SingleM uses conserved single-copy marker genes to profile microbial communities and estimate the prokaryotic fraction of each sample. Its marker-gene approach is complementary to MetaPhlAn's clade-specific markers.

| Attribute | Value |
|-----------|-------|
| Tool | [SingleM](https://github.com/wwood/singlem) |
| Version | 0.20.3 |
| Reference taxonomy | GTDB r226 |
| Database package | `S5.4.0.GTDB_r226.metapackage_20250331.smpkg.zb` (~7 GB) |
| Config flag | `singlem` (default: `true`) |
| Rules | `dl_singlem_DB`, `singlem_profile`, `singlem_extra`, `singlem_merged_table`, `singlem_merge_prokaryotic_fraction` |
| Rule file | `Workflow/rules/singlem.smk` |
| Default threads | 10 |
| Default RAM | 40 GB |
| Default wall time | 23 h |

---

## Enable / Disable

SingleM is **on by default**. To disable:

```bash
snakemake --config singlem=false
```

---

## Rules

### `dl_singlem_DB`

Downloads the SingleM metapackage on first run.

### `singlem_profile`

Profiles each sample using marker genes.

**Input:**
- `Data/NoHuman/{sample}_R1_001.fastq.gz`
- `Data/NoHuman/{sample}_R2_001.fastq.gz`
- SingleM metapackage

**Output:**
| File | Description |
|------|-------------|
| `Data/SingleM/{sample}/{sample}_profile.tsv` | Taxonomic profile |
| `Data/SingleM/{sample}/{sample}_otu-table.tsv` | OTU table |

### `singlem_extra`

Runs additional SingleM analyses using the pre-computed profile.

**Output:**
| File | Description |
|------|-------------|
| `{sample}_species_by_site.tsv` | Species abundance by marker gene site |
| `{sample}_longform.tsv` | Expanded taxonomic profile |
| `{sample}.spf.tsv` | Prokaryotic fraction estimate |

Wall time: 480 min

### `singlem_merged_table`

Merges per-sample profiles into a cohort-level table.

**Output:**
| File | Description |
|------|-------------|
| `Data/SingleM/table/merged_profile.tsv` | All samples combined |
| `Data/SingleM/table/species_by_site/` | Directory of species-level tables per marker site |

### `singlem_merge_prokaryotic_fraction`

Combines per-sample prokaryotic fraction estimates.

**Output:** `Data/SingleM/table/merged_prokaryotic_fraction.tsv`

---

## Prokaryotic Fraction

The `{sample}.spf.tsv` file reports the estimated fraction of reads derived from prokaryotes (as opposed to host, eukaryotes, or unclassified sequences). This is useful for:

- Normalizing community profiles
- Quality-checking samples for low-biomass contamination
- Combining with microbial load estimates (see [MLP]({% link modules/mlp.md %}))

---

## Thread Configuration

```yaml
threads:
  singlem: 10
```
