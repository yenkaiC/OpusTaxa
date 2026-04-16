---
layout: default
title: Home
nav_order: 1
description: "OpusTaxa — a comprehensive Snakemake pipeline for end-to-end metagenomic analysis"
permalink: /
---

# OpusTaxa
{: .fs-9 }

A comprehensive Snakemake pipeline for end-to-end metagenomic analysis — from raw reads to taxonomic profiles, functional annotations, resistance genes, biosynthetic clusters, and more.
{: .fs-6 .fw-300 }

[Get Started]({% link installation.md %}){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[View on GitHub](https://github.com/yenkaiC/OpusTaxa){: .btn .fs-5 .mb-4 .mb-md-0 }

---

## Overview

OpusTaxa is a modular, reproducible metagenomics pipeline built with [Snakemake](https://snakemake.readthedocs.io). It handles everything from quality control through to strain-level phylogenetics in a single, configurable workflow.

All tools run in isolated [Conda](https://docs.conda.io) environments (or Singularity containers on HPC), databases are auto-downloaded on first run, and every module can be toggled independently.

---

## Workflow at a Glance

```
Raw FASTQ
    │
    ├─► FastQC (raw QC)
    │
    ▼
fastp (trimming)
    │
    ├─► FastQC (post-trim QC)
    │
    ▼
NoHuman (host removal)
    │
    ├─► FastQC + MultiQC
    │
    ├─► MetaPhlAn 4  ──► Merged abundance table
    │       └──► StrainPhlAn (strain phylogenies)
    │       └──► HUMAnN 3    (functional profiling)
    │       └──► MLP          (microbial load prediction)
    │
    ├─► SingleM      ──► Prokaryotic fraction estimates
    │
    ├─► Kraken2 + Bracken ──► Species abundance table
    │
    └─► MetaSPAdes (assembly)
            ├─► RGI        (resistance genes)
            ├─► AntiSMASH  (biosynthetic gene clusters)
            └─► Prodigal-GV (gene prediction)
```

---

## Modules

| Module | Default | Description |
|--------|---------|-------------|
| [Quality Control]({% link modules/qc.md %}) | Always on | FastQC + MultiQC at three pipeline stages |
| [fastp]({% link modules/fastp.md %}) | Always on | Adapter trimming and quality filtering |
| [NoHuman]({% link modules/nohuman.md %}) | Always on | Human read removal (HPRC Kraken2 database) |
| [MetaPhlAn]({% link modules/metaphlan.md %}) | **On** | Species-level taxonomic profiling |
| [SingleM]({% link modules/singlem.md %}) | **On** | Marker gene profiling + prokaryotic fraction |
| [Kraken2]({% link modules/kraken2.md %}) | Off | k-mer classification + Bracken abundance |
| [MetaSPAdes]({% link modules/metaspades.md %}) | Off | Metagenome assembly |
| [HUMAnN]({% link modules/humann.md %}) | Off | Functional gene families and pathways |
| [RGI]({% link modules/rgi.md %}) | Off | Antibiotic resistance gene identification |
| [AntiSMASH]({% link modules/antismash.md %}) | Off | Biosynthetic gene cluster detection |
| [MLP]({% link modules/mlp.md %}) | Off | Microbial load prediction |
| [StrainPhlAn]({% link modules/strainphlan.md %}) | Off | Strain-level phylogenetics |
| [Prodigal-GV]({% link modules/prodigal-gv.md %}) | Off | Gene prediction (incl. giant viruses) |

---

## Key Features

- **Fully automated** — databases download on first run; subsequent runs use cached copies
- **Modular** — enable only the tools you need via `--config` flags
- **Reproducible** — pinned tool versions, per-tool Conda environments
- **HPC-ready** — native SLURM support; optional Singularity containers
- **Flexible input** — accepts seven common paired-end FASTQ naming conventions
- **SRA integration** — download public datasets directly from NCBI

---

## Citation

If you use OpusTaxa in your research, please cite it using the metadata in [CITATION.cff](https://github.com/yenkaiC/OpusTaxa/blob/main/CITATION.cff).
