---
layout: default
title: MetaSPAdes (Assembly)
parent: Modules
nav_order: 7
---

# MetaSPAdes — Metagenome Assembly
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Overview

MetaSPAdes assembles short paired-end reads into longer contigs and scaffolds. The assembled contigs serve as input for RGI, AntiSMASH, and Prodigal-GV.

| Attribute | Value |
|-----------|-------|
| Tool | [SPAdes](https://github.com/ablab/spades) (metagenomic mode) |
| Version | 4.2.0 |
| Config flag | `metaspades` (default: `false`) |
| Rules | `metaspades` |
| Rule file | `Workflow/rules/metaspades.smk` |
| Default threads | 12 |
| Default RAM | **100 GB** |
| Default wall time | 48 h |

---

## Enable

```bash
snakemake --use-conda --cores 32 --config metaspades=true
```

{: .warning }
MetaSPAdes requires **100 GB of RAM** and can run for up to **48 hours** per sample on complex communities. Only run on HPC nodes with sufficient memory.

---

## What It Does

- Runs SPAdes in `--meta` mode for metagenome assembly
- Assembles paired-end reads into contigs and scaffolds
- Intermediate SPAdes files are removed after assembly to save disk space — only contigs and scaffolds are retained

---

## Input / Output

**Input:**
- `Data/NoHuman/{sample}_R1_001.fastq.gz`
- `Data/NoHuman/{sample}_R2_001.fastq.gz`

**Output:**
| File | Description | Used By |
|------|-------------|---------|
| `Data/MetaSPAdes/{sample}/contigs.fasta` | Assembled contigs | RGI |
| `Data/MetaSPAdes/{sample}/scaffolds.fasta` | Scaffolded assembly | HUMAnN (protein search), AntiSMASH, Prodigal-GV |

---

## Downstream Dependencies

The following modules require MetaSPAdes output:

| Module | Uses |
|--------|------|
| [RGI]({% link modules/rgi.md %}) | `contigs.fasta` |
| [AntiSMASH]({% link modules/antismash.md %}) | `contigs.fasta` (filtered to ≥1000 bp) |
| [Prodigal-GV]({% link modules/prodigal-gv.md %}) | `contigs.fasta` |

Enable them together:

```bash
snakemake --config metaspades=true rgi=true antismash=true prodigal_gv=true
```

---

## Thread Configuration

```yaml
threads:
  metaspades: 12
```

For large-memory HPC nodes, increasing threads can reduce wall time:

```bash
snakemake --config threads.metaspades=32
```
