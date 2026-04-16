---
layout: default
title: NoHuman (Host Removal)
parent: Modules
nav_order: 2
---

# NoHuman — Host Read Removal
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Overview

NoHuman removes human (host) reads using a Kraken2 database built from the Human Pangenome Reference Consortium (HPRC) reference. It runs automatically on every sample.

| Attribute | Value |
|-----------|-------|
| Tool | [NoHuman](https://github.com/mbhall88/nohuman) |
| Version | 0.5.0 |
| Database | HPRC.r2 (~5.9 GB) |
| Rules | `dl_noHuman_DB`, `remove_human_reads`, `nohuman_summary` |
| Rule file | `Workflow/rules/nohuman.smk` |
| Default threads | 8 |
| Default RAM | 32 GB |
| Default wall time | 8 h |

---

## What It Does

1. **`dl_noHuman_DB`** — Downloads and caches the HPRC.r2 Kraken2 database on first run. Subsequent runs are skipped automatically.
2. **`remove_human_reads`** — Classifies reads against the human database and discards those matching human sequences. The cleaned reads are written to `Data/NoHuman/`.
3. **`nohuman_summary`** — Parses NoHuman logs to generate a TSV report showing total reads, human reads removed, and percentages for each sample.

---

## Input / Output

| Direction | Path |
|-----------|------|
| Input R1 | `Data/FastP/{sample}_R1_001.fastq.gz` |
| Input R2 | `Data/FastP/{sample}_R2_001.fastq.gz` |
| Output R1 | `Data/NoHuman/{sample}_R1_001.fastq.gz` |
| Output R2 | `Data/NoHuman/{sample}_R2_001.fastq.gz` |
| Summary | `Data/NoHuman/nohuman_summary.tsv` |

### `nohuman_summary.tsv` Columns

| Column | Description |
|--------|-------------|
| `sample` | Sample identifier |
| `total_reads` | Total input read pairs |
| `human_reads` | Read pairs classified as human |
| `non_human_reads` | Read pairs retained |
| `percent_human` | Percentage removed |
| `percent_non_human` | Percentage retained |

---

## Thread Configuration

```yaml
# config/config.yaml
threads:
  nohuman: 8
```
