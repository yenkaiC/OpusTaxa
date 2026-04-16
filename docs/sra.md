---
layout: default
title: SRA Downloads
nav_order: 9
---

# Downloading Data from NCBI SRA
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Overview

OpusTaxa can automatically download paired-end FASTQ files from [NCBI SRA](https://www.ncbi.nlm.nih.gov/sra) before running the analysis.

| Attribute | Value |
|-----------|-------|
| Tool | sra-tools (`fasterq-dump`) + pigz |
| sra-tools version | 3.2.1 |
| Config flag | `download_sra` (default: `false`) |
| Rule file | `Workflow/rules/sra.smk` |

---

## Step 1 — List Accession IDs

Add your SRA accession IDs to `sra_id.txt`, one per line:

```
SRR27916045
SRR27916046
ERR1234567
```

Supports both SRR (NCBI) and ERR (ENA) accessions.

---

## Step 2 — Run with SRA Download

```bash
snakemake --use-conda --cores 8 --config download_sra=true
```

The pipeline will:
1. Download each accession with `fasterq-dump` (8 threads, parallel)
2. Compress with `pigz` (parallel gzip)
3. Place compressed files in `Data/Raw_FastQ/` as `{sra_id}_1.fastq.gz` / `{sra_id}_2.fastq.gz`
4. Continue with the standard analysis pipeline

---

## Rules

### `SRA_downloader`

Downloads raw FASTQ using `fasterq-dump`.

| Resource | Value |
|----------|-------|
| RAM | 22 GB |
| Threads | 8 |
| Wall time | 400 min |

Output: Uncompressed `{sra_id}_1.fastq` and `{sra_id}_2.fastq` (temporary — deleted after compression).

### `parallel_gzip`

Compresses downloaded FASTQ using `pigz`.

| Resource | Value |
|----------|-------|
| RAM | 24 GB |
| Threads | 8 |
| Wall time | 240 min |

Output: `Data/Raw_FastQ/{sra_id}_1.fastq.gz` and `Data/Raw_FastQ/{sra_id}_2.fastq.gz`

---

## Combining SRA Data with Local Data

You can mix SRA downloads with locally placed FASTQ files. Put local files in `Data/Raw_FastQ/` as usual and list SRA IDs in `sra_id.txt`. OpusTaxa will process both together.

---

## HPC Notes

SRA downloads require internet access. On HPC systems where compute nodes are isolated:

1. Download SRA data on the login node:
   ```bash
   snakemake --use-conda --cores 4 --config download_sra=true \
       --until parallel_gzip
   ```
2. Once downloads complete, submit the analysis jobs normally:
   ```bash
   snakemake --workflow-profile config/slurm \
       --config metaphlan=true singlem=true
   ```
