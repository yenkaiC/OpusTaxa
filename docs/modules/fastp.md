---
layout: default
title: fastp (Trimming)
parent: Modules
nav_order: 1
---

# fastp — Quality Trimming
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Overview

fastp performs adapter trimming and quality filtering on raw paired-end reads. It runs automatically on every sample and cannot be disabled — it is a prerequisite for all downstream modules.

| Attribute | Value |
|-----------|-------|
| Tool | [fastp](https://github.com/OpenGene/fastp) |
| Version | 1.1.0 |
| Rule | `fastp_trim` |
| Rule file | `Workflow/rules/fastp.smk` |
| Default threads | 10 |
| Default RAM | 32 GB |
| Default wall time | 8 h |

---

## What It Does

- Removes adapter sequences (auto-detected)
- Filters reads below quality threshold
- Trims low-quality bases from read ends
- Removes reads shorter than a minimum length

---

## Input / Output

| Direction | Path |
|-----------|------|
| Input R1 | `Data/Raw_FastQ/{sample}_R1_001.fastq.gz` |
| Input R2 | `Data/Raw_FastQ/{sample}_R2_001.fastq.gz` |
| Output R1 | `Data/FastP/{sample}_R1_001.fastq.gz` |
| Output R2 | `Data/FastP/{sample}_R2_001.fastq.gz` |

{: .note }
Non-standard FASTQ filenames are automatically symlinked to the `_R1_001.fastq.gz` / `_R2_001.fastq.gz` convention by the `standardize_filenames` rule before fastp runs.

---

## Thread Configuration

```yaml
# config/config.yaml
threads:
  fastp: 10
```

Or override at runtime:
```bash
snakemake --config threads.fastp=16
```
