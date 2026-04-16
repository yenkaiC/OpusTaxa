---
layout: default
title: Installation
nav_order: 2
---

# Installation
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Prerequisites

| Requirement | Minimum Version | Notes |
|-------------|----------------|-------|
| [Snakemake](https://snakemake.readthedocs.io) | 7.0 | Workflow engine |
| [Conda / Mamba](https://github.com/conda-forge/miniforge) | Any | Environment management |
| Python | 3.8+ | Required by Snakemake |
| Storage | 150 GB free | For all databases; see [Databases]({% link databases.md %}) |
| RAM | 16 GB minimum | 100 GB recommended for MetaSPAdes |

{: .note }
**Mamba** is strongly recommended over Conda for faster environment resolution. Install it via [Miniforge](https://github.com/conda-forge/miniforge).

---

## Step 1 — Clone the Repository

```bash
git clone https://github.com/yenkaiC/OpusTaxa.git
cd OpusTaxa
```

---

## Step 2 — Install Snakemake

Create a dedicated Conda environment:

```bash
conda create -n snakemake -c conda-forge -c bioconda snakemake
conda activate snakemake
```

Or with Mamba (faster):

```bash
mamba create -n snakemake -c conda-forge -c bioconda snakemake
conda activate snakemake
```

---

## Step 3 — Place Your Data

Put your paired-end FASTQ files in `Data/Raw_FastQ/`. OpusTaxa accepts seven common naming conventions and automatically standardizes them via symlinks (your original files are never modified):

| Format | Example |
|--------|---------|
| Illumina bcl2fastq (with lane) | `sample_S1_L001_R1_001.fastq.gz` |
| Illumina (no lane) | `sample_S1_R1_001.fastq.gz` |
| Standard | `sample_R1_001.fastq.gz` |
| Simple paired | `sample_R1.fastq.gz` |
| SRA / ENA | `sample_1.fastq.gz` |
| Dot-separated (R) | `sample.R1.fastq.gz` |
| Dot-separated (number) | `sample.1.fastq.gz` |

{: .important }
OpusTaxa requires **paired-end reads**. Single-end reads are not supported.

To use a different input directory:
```bash
snakemake --config inputFastQDirectory=/path/to/fastqs ...
```

---

## Step 4 — Run a Dry-Run

Verify Snakemake can parse the workflow and detect your samples:

```bash
snakemake --use-conda --cores 8 --dry-run
```

The output will list all jobs to be executed. Check that your expected samples appear.

---

## Step 5 — Run the Pipeline

```bash
snakemake --use-conda --cores 8
```

By default this runs the always-on modules (fastp, NoHuman, FastQC, MultiQC) plus MetaPhlAn and SingleM. See [Configuration]({% link configuration.md %}) to enable additional modules.

---

## Test Mode

A small test dataset is included in `Misc/Test/Raw_FastQ/`. Run it to verify your installation without using your own data:

```bash
snakemake --use-conda --cores 8 --config test_mode=true
```

---

## HPC / SLURM Installation

If running on a cluster, see the dedicated [HPC Guide]({% link hpc.md %}) for SLURM profile setup and Singularity container usage.
