---
layout: default
title: Kraken2 + Bracken
parent: Modules
nav_order: 6
---

# Kraken2 + Bracken — k-mer Classification
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Overview

Kraken2 performs fast k-mer based taxonomic classification of reads. Bracken then re-distributes unclassified reads to produce accurate species-level abundance estimates.

| Attribute | Value |
|-----------|-------|
| Tool | [Kraken2](https://github.com/DerrickWood/kraken2) + [Bracken](https://github.com/jenniferlu717/Bracken) |
| Version | Kraken2 2.1.6 |
| Database | PlusPF-16 (16 GB) |
| Config flag | `kraken2` (default: `false`) |
| Rules | `dl_kraken2_DB`, `kraken2`, `bracken`, `combine_bracken_reports` |
| Rule file | `Workflow/rules/kraken2.smk` |
| Default threads | 8 |
| Default RAM | 64 GB (classification) |
| Default wall time | 8 h |

---

## Enable

```bash
snakemake --use-conda --cores 16 --config kraken2=true
```

---

## Database

**PlusPF-16** includes sequences from:
- Archaea
- Bacteria
- Viruses
- Plasmids
- Human
- UniVec_Core
- Protozoa
- Fungi

Database source: AWS S3 (`k2_pluspf_16_GB_20251015.tar.gz`, ~16 GB).

{: .note }
Kraken2 loads the entire database into RAM. Ensure at least **64 GB** of available memory.

---

## Rules

### `dl_kraken2_DB`

Downloads and extracts the PlusPF-16 database. Checkpoint: `Database/kraken2/.download_complete`.

### `kraken2`

Classifies paired-end reads.

**Input:**
- `Data/NoHuman/{sample}_R1_001.fastq.gz`
- `Data/NoHuman/{sample}_R2_001.fastq.gz`

**Output:**
| File | Description |
|------|-------------|
| `Data/Kraken2/{sample}/{sample}_report.txt` | Per-taxon read counts (Kraken2 report format) |
| `Data/Kraken2/{sample}/{sample}_output.txt` | Per-read classification assignments |

Runs in paired-end mode with gzip input (`--paired --gzip-compressed`).

### `bracken`

Re-estimates species abundances from Kraken2 output.

**Input:** `{sample}_report.txt`

**Output:**
| File | Description |
|------|-------------|
| `{sample}_bracken.txt` | Abundance estimates |
| `{sample}_bracken_report.txt` | Species-level Kraken2-format report |

Default parameters:
- Read length: 150 bp — adjust if your reads differ
- Classification level: Species (`S`)

### `combine_bracken_reports`

Merges all sample Bracken reports into a single table.

**Output:** `Data/Kraken2/table/combined_bracken_species.txt`

---

## Adjusting Read Length for Bracken

If your reads are not 150 bp, update the Bracken rule in `Workflow/rules/kraken2.smk`:

```python
params:
    read_length = 100   # change to match your data
```

Or add it to `config/config.yaml`:

```yaml
bracken_read_length: 100
```

---

## Thread Configuration

```yaml
threads:
  kraken2: 8
```
