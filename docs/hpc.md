# Running OpusTaxa on an HPC (SLURM)

This guide covers running OpusTaxa on a SLURM-managed HPC cluster. If you are running on a local workstation or laptop, see [local.md](local.md) instead.

---

## Installation

Run these commands from the **login node**:

```bash
# 1. Clone the repository
git clone https://github.com/yenkaiC/OpusTaxa.git
cd OpusTaxa

# 2. Create and activate a Snakemake environment
conda create -n snakemake -c conda-forge -c bioconda snakemake
conda activate snakemake

# 3. Install the SLURM executor plugin
pip install snakemake-executor-plugin-slurm

# 4. Verify the setup with a dry-run
snakemake --workflow-profile config/slurm --dry-run
```

---

## Critical: Always Run from the Login Node

**Never submit Snakemake itself as an `sbatch` job.** Snakemake is a job orchestrator — it needs continuous access to the SLURM controller to submit and monitor jobs. Running it inside a compute job breaks this.

Instead, run Snakemake in a persistent terminal session on the login node using `screen` or `tmux`, or `nohup` so it keeps running if your SSH connection drops.
```bash
cd OpusTaxa
conda activate snakemake

# Option 1: screen
screen -S opustaxa
snakemake --workflow-profile config/slurm --dry-run
# Detach:   Ctrl+A, then D
# Reattach: screen -r opustaxa

# Option 2: tmux
tmux new -s opustaxa
snakemake --workflow-profile config/slurm --dry-run
# Detach:   Ctrl+B, then D
# Reattach: tmux attach -t opustaxa
```

---

## Preparing Your Input

**Option A — Local FASTQ files**

Place your paired-end FASTQ files in `Data/Raw_FastQ/`, or point OpusTaxa to an existing directory:

```bash
snakemake --workflow-profile config/slurm \
    --config inputFastQDirectory=/path/to/your/fastq
```

OpusTaxa automatically detects and standardises naming conventions (Illumina bcl2fastq, SRA, ENA, dot-separated). Your original files are never modified.

**Option B — SRA accessions**

Add SRA run IDs to `sra_id.txt`, one per line:

```
SRR27916045
SRR27916046
SRR27916047
```

Then run with `download_sra=true` (see below).

> **Tip:** Start with 2–3 samples to verify everything works before committing to a full dataset.

---

## Running the Pipeline

All HPC runs use `--workflow-profile config/slurm`. Do **not** use `--use-conda` for HPC runs — the profile handles job submission automatically.

```bash
# Default run — MetaPhlAn and SingleM enabled
snakemake --workflow-profile config/slurm

# Dry-run first (recommended)
snakemake --workflow-profile config/slurm --dry-run

# Download SRA data and run
snakemake --workflow-profile config/slurm --config download_sra=true

# Enable additional modules
snakemake --workflow-profile config/slurm \
    --config kraken2=true humann=true metaspades=true rgi=true antismash=true

# Disable MetaPhlAn, keep SingleM only
snakemake --workflow-profile config/slurm \
    --config metaphlan=false singlem=true

# Specify a custom input directory
snakemake --workflow-profile config/slurm \
    --config inputFastQDirectory=/scratch/user/myproject/fastq
```

---

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
| Strain-level analysis (StrainPhlAn) | `strainphlan=true` | Off |

---

## Database Downloads

Many HPC compute nodes do not have internet access. Databases **must be downloaded on the login node** before submitting the full pipeline.

Only download databases for the tools you plan to use:

```bash
conda activate snakemake

# Core (always needed)
snakemake --use-conda --cores 1 --until dl_noHuman_DB

# Taxonomic profiling
snakemake --use-conda --cores 1 --until dl_metaphlan_DB    # MetaPhlAn
snakemake --use-conda --cores 1 --until dl_singlem_DB      # SingleM
snakemake --use-conda --cores 1 --until dl_kraken2_DB      # Kraken2

# Functional profiling
snakemake --use-conda --cores 1 \
    --until dl_humann_chocophlan dl_humann_uniref dl_humann_utility

# Resistome / BGC
snakemake --use-conda --cores 1 --until dl_card_DB
snakemake --use-conda --cores 1 --until antismash_download_databases
```

Database sizes (uncompressed): NoHuman ~6 GB · MetaPhlAn ~34 GB · SingleM ~7 GB · Kraken2 ~16 GB · HUMAnN ~52 GB · RGI ~17 GB · antiSMASH ~9 GB

---

## Customising Threads and Memory

Edit `config/config.yaml` to adjust thread allocations:

```yaml
threads:
  fastp: 10
  nohuman: 8
  metaphlan: 8
  singlem: 10
  metaspades: 24
  humann: 10
```

Or override on the command line:

```bash
snakemake --workflow-profile config/slurm \
    --config threads='{"metaspades": 32, "metaphlan": 16}'
```

---

## Monitoring Jobs

```bash
# View your running and pending jobs
squeue -u $(whoami)

# Check a specific job log
cat .snakemake/slurm_logs/rule_metaphlan/<sample>/12345.log
```

---

