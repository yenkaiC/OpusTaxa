---
title: "OpusTaxa"
author: "Feargal Ryan"
date: "2026"
---

# OpusTaxa: A Unified Workflow for Taxonomic Profiling, Assembly, and Functional Analysis of Shotgun Metagenomes

OpusTaxa is an open-source [Snakemake](snakemake.md) workflow for end-to-end processing of short paired-end shotgun metagenomic data. It is designed for life scientists who want reproducible, best-practice metagenome analysis without requiring advanced bioinformatics expertise.

Users provide either FASTQ files or Sequence Read Archive (SRA) accessions. OpusTaxa automatically downloads all required databases, performs quality control, removes host reads, and runs taxonomic profiling, metagenome assembly, and functional analysis. All modules can be independently toggled, and per-sample outputs are automatically merged into harmonised cross-sample tables ready for downstream exploration.

<img src="../Misc/OpusTaxa_subway 23Feb2026.png" alt="OpusTaxa pipeline overview" width="100%">

---

## Authors

Yen-Kai Chen, Clarice M. Harker, Cong M. Pham, Luke Grundy, Hannah R. Wardill, Michael J. Roach, **Feargal J. Ryan**

Flinders Health and Medical Research Institute, Flinders University, Bedford Park, SA 5042, Australia.

Correspondence: feargal.ryan@flinders.edu.au · michael.roach@flinders.edu.au

---

## Installation

OpusTaxa requires [conda](https://docs.conda.io/en/latest/) and Snakemake. All other software is installed automatically when the pipeline runs.

```bash
# 1. Clone the repository
git clone https://github.com/yenkaiC/OpusTaxa.git
cd OpusTaxa

# 2. Create and activate a Snakemake environment
conda create -n snakemake -c conda-forge -c bioconda snakemake
conda activate snakemake

# 3. Check everything is in order with a dry-run
snakemake --use-conda --dry-run --cores 1
```

A dry-run prints the steps Snakemake would execute without running anything. This is a good way to confirm the pipeline is set up correctly before committing to a full run.

---

## Input

OpusTaxa accepts two input methods.

**Option A: Local FASTQ files**

Place paired-end FASTQ files in `Data/Raw_FastQ/`. OpusTaxa automatically detects and standardises a wide range of common naming conventions (Illumina bcl2fastq, SRA, ENA, dot-separated, etc.) — your original files are not modified.

```
Data/Raw_FastQ/
├── sample1_R1_001.fastq.gz
├── sample1_R2_001.fastq.gz
├── sample2_R1_001.fastq.gz
└── sample2_R2_001.fastq.gz
```

**Option B: SRA accessions**

Add SRA run IDs to `sra_id.txt`, one per line:

```
SRR27916045
SRR27916046
SRR27916047
```

OpusTaxa will download, compress, and process them automatically.

---

## Running the Pipeline

**Local execution:**

```bash
# Default run (MetaPhlAn and SingleM enabled)
snakemake --use-conda --cores 16

# Enable additional modules
snakemake --use-conda --cores 16 --config kraken2=true humann=true metaspades=true rgi=true antismash=true

# Download SRA data and run
snakemake --use-conda --cores 16 --config download_sra=true
```

**HPC (SLURM):**

```bash
snakemake --workflow-profile config/slurm
```

Run Snakemake from the login node inside a `screen` or `tmux` session so it keeps running if your SSH connection drops. See the [full documentation](https://github.com/yenkaiC/OpusTaxa) for SLURM setup instructions.

---

## Pipeline Modules

| Module | Tool | Default |
|--------|------|---------|
| Quality control | fastp | On |
| Host read removal | NoHuman | On |
| QC reports | FastQC + MultiQC | On |
| Taxonomic profiling | MetaPhlAn 4 | On |
| Taxonomic profiling | SingleM | On |
| Taxonomic profiling | Kraken2 + Bracken | Off |
| Metagenome assembly | MetaSPAdes | Off |
| Functional profiling | HUMAnN 3 | Off |
| Resistance gene identification | RGI (CARD) | Off |
| Biosynthetic gene clusters | antiSMASH | Off |
| Microbial load prediction | MLP | Off |
| Strain-level analysis | StrainPhlAn | Off |

---

## Taxonomic Classification

OpusTaxa runs three independent taxonomic classifiers on every sample. This multi-tool strategy provides an internal validation layer: signals that are consistent across tools with different algorithms and different reference databases are more likely to reflect genuine biology rather than tool-specific artefacts. MetaPhlAn is the primary output; SingleM and optionally Kraken2 serve as orthogonal checks.

See the [Taxonomic Classification](taxonomic-classification.md) page for a full description and comparison of the three tools.

---

## Outputs

All results are written to the `Data/` directory. Tables from MetaPhlAn, SingleM, Kraken2, and HUMAnN are merged across all samples into single files ready for statistical analysis.

```
Data/
├── MetaPhlAn/Table/        # Relative abundance table (all samples)
├── SingleM/Table/          # OTU tables at multiple taxonomic levels
├── Kraken2/Table/          # Bracken species abundance table
├── HUMAnN/merged/          # Gene families and pathway abundances
├── MetaSPAdes/             # Assembled contigs
├── RGI/Table/              # Resistance gene table
├── AntiSMASH/Table/        # Biosynthetic gene cluster summary
└── MLP/                    # Predicted microbial load

Reports/
├── FastQC/                 # Per-sample QC reports (raw, trimmed, filtered)
└── MultiQC/                # Aggregated QC summaries
```

---

## Resource Requirements

| | Minimum | Recommended |
|-|---------|-------------|
| CPU | 4 cores | 16+ cores |
| RAM | 16 GB | 64+ GB |
| Storage | 100 GB | 500 GB |

Database sizes (uncompressed): NoHuman ~6 GB · MetaPhlAn ~34 GB · SingleM ~7 GB · Kraken2 ~16 GB · HUMAnN ~52 GB

All databases are downloaded automatically on first run.

---

## Citation

If you use OpusTaxa, please cite:

> Chen Y-K, Harker CM, Pham CM, Grundy L, Wardill HR, Roach MJ, Ryan FJ. *OpusTaxa: A Unified Workflow for Taxonomic Profiling, Assembly, and Functional Analysis of Shotgun Metagenomes.* 2026.

OpusTaxa coordinates and executes a number of independent tools, each of which should also be cited in your methods. Please cite the tools you used:

### Example methods statement

> Metagenomic data were analysed using the OpusTaxa Snakemake pipeline (version]; Chen et al. 2026). Briefly, raw paired-end reads were quality controlled with fastp [1] and host reads were removed with NoHuman [2]. Read quality were visualised with FastQC [3] and summarised with MultiQC [4] Taxonomic profiles were generated with MetaPhlAn4 [5]

---

## Further Reading

- [What is Metagenomics?](what-is-metagenomics.md)
- [What is Snakemake?](snakemake.md)
- [Taxonomic Classification in OpusTaxa](taxonomic-classification.md)
- [GitHub Repository](https://github.com/yenkaiC/OpusTaxa)
