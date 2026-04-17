# Running OpusTaxa Locally

This guide covers running OpusTaxa on your own laptop or workstation. If you are running on an HPC cluster with SLURM, see [hpc.md](hpc.md) instead.


## Prerequisites

- [conda](https://docs.conda.io/en/latest/) or [mamba](https://mamba.readthedocs.io/) installed
- At least 16 GB RAM (64+ GB recommended for production runs)
- At least 100 GB free storage (500 GB recommended)


## Installation

```bash
# 1. Clone the repository
git clone https://github.com/yenkaiC/OpusTaxa.git
cd OpusTaxa

# 2. Create and activate a Snakemake environment
conda create -n snakemake -c conda-forge -c bioconda snakemake
conda activate snakemake

# 3. Verify the setup with a dry-run
snakemake --use-conda --dry-run --cores 1
```

A dry-run prints every step Snakemake would execute without running anything. If it completes without errors your installation is ready.


## Preparing Your Input

**Option A — Local FASTQ files**

Place your paired-end FASTQ files in `Data/Raw_FastQ/`:

```
Data/Raw_FastQ/
├── sample1_R1_001.fastq.gz
├── sample1_R2_001.fastq.gz
├── sample2_R1_001.fastq.gz
└── sample2_R2_001.fastq.gz
```

OpusTaxa automatically detects and standardises a wide range of naming conventions (Illumina bcl2fastq, SRA, ENA, dot-separated). Your original files are never modified.

If your files are stored elsewhere, point OpusTaxa to them at runtime:

```bash
snakemake --use-conda --cores 16 \
    --config inputFastQDirectory=/path/to/your/fastq
```

**Option B — SRA accessions**

Add SRA run IDs to `sra_id.txt`, one per line:

```
SRR27916045
SRR27916046
SRR27916047
```

Then run with `download_sra=true` (see below).

> **Tip:** Start with 2–3 samples to verify everything works before committing to a full dataset.


## Running the Pipeline

All local runs use `--use-conda`. Snakemake will automatically create isolated software environments for each tool — you do not need to install MetaPhlAn, SingleM, or any other tool yourself.

```bash
# Default run — MetaPhlAn and SingleM enabled
snakemake --use-conda --cores 16

# Dry-run first (recommended)
snakemake --use-conda --dry-run --cores 16

# Download SRA data and run
snakemake --use-conda --cores 16 --config download_sra=true

# Enable additional modules
snakemake --use-conda --cores 16 \
    --config kraken2=true humann=true metaspades=true rgi=true antismash=true

# Disable MetaPhlAn, keep SingleM only
snakemake --use-conda --cores 16 --config metaphlan=false singlem=true

# Run with built-in test files
snakemake --use-conda --cores 8 --config test_mode=true
```

Set `--cores` to the number of CPU cores available on your machine.


## Available Modules

| Module | Flag | Default |
|--------|-------|---------|
| Quality control (fastp) | always on | On |
| Host read removal (NoHuman) | always on | On |
| QC reports (FastQC + MultiQC) | always on | On |
| Taxonomic profiling (MetaPhlAn 4) | `metaphlan=true/false` | On |
| Taxonomic profiling (SingleM) | `singlem=true/false` | On |
| Taxonomic profiling (Kraken2 + Bracken) | `kraken2=true` | Off |
| Metagenome assembly (MetaSPAdes) | `metaspades=true` | Off |
| Functional profiling (HUMAnN 3) | `humann=true` | Off |
| Resistance genes (RGI / CARD) | `rgi=true` | Off |
| Biosynthetic gene clusters (antiSMASH) | `antismash=true` | Off |
| Microbial load prediction (MLP) | `mlp=true` | Off |

### Database Size (Uncompressed)
- NoHuman: ~5.9 GB (As of February 2026)
- MetaPhlAn: ~34 GB ([Version 4.2.4 - mpa_vJan25_CHOCOPhlAnSGB_202503](https://github.com/biobakery/MetaPhlAn/wiki/MetaPhlAn-4.2))
- SingleM: ~7 GB ([Version S5.4.0](https://zenodo.org/records/15232972))
- HUMAnN: ~52 GB (HUMAnN 3.9)
- Kraken2: 16 GB ([PlusPF-16](https://benlangmead.github.io/aws-indexes/k2))
- RGI: ~16.8 GB (As of February 2026 [latest](https://card.mcmaster.ca/download))
- AntiSMASH: ~ 9.4GB (Version 8.0.4)

Databases are **downloaded automatically** on first run (~140 GB total if all modules enabled).

## Customising Threads

Edit `config/config.yaml` to adjust how many CPU threads each tool uses:

```yaml
threads:
  fastp: 10
  nohuman: 8
  metaphlan: 8
  singlem: 10
  metaspades: 12
  humann: 10
```

Or override on the command line:

```bash
snakemake --use-conda --cores 16 \
    --config threads='{"metaspades": 12, "metaphlan": 8}'
```

