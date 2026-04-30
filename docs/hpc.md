# Running OpusTaxa on an HPC (SLURM)

This guide covers running OpusTaxa on a SLURM-managed HPC cluster. If you are running on a local workstation or laptop, see [local.md](local.md) instead.


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


## Critical: Always Run from the Login Node

**Never submit Snakemake itself as an `sbatch` job.** Snakemake is a job orchestrator — it needs continuous access to the SLURM controller to submit and monitor jobs. Running it inside a compute job breaks this.

Instead, run Snakemake in a persistent terminal session on the login node using `screen` or `tmux`, or `nohup` so it keeps running if your SSH connection drops.
```bash
cd OpusTaxa

# Option 1: screen
screen -S opustaxa
conda activate snakemake
snakemake --workflow-profile config/slurm --dry-run
# Detach:   Ctrl+A, then D
# Reattach: screen -r opustaxa

# Option 2: tmux
tmux new -s opustaxa
conda activate snakemake
snakemake --workflow-profile config/slurm --dry-run
# Detach:   Ctrl+B, then D
# Reattach: tmux attach -t opustaxa
```


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
# All modules are controlled with `--config`. You can add as many flags as needed to the same command:
snakemake --workflow-profile config/slurm \
    --config kraken2=true humann=true metaspades=true rgi=true antismash=true prodigal_gv=true

# Disable MetaPhlAn, keep SingleM only
snakemake --workflow-profile config/slurm \
    --config metaphlan=false singlem=true

# Specify a custom input directory
snakemake --workflow-profile config/slurm \
    --config inputFastQDirectory=/scratch/user/myproject/fastq
```

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
| Prodigal-gv | `prodigal_gv=true` | Off |
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

## Database Downloads

Some HPC compute nodes do not have internet access. Databases **must be downloaded on the login node** before submitting the full pipeline if that's the case for your HPC.

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
# humann downloads from globus, if it's still not downloading, please contact your hpc technicians as your hpc may have blocked downloading from this server

# Resistome / BGC
snakemake --use-conda --cores 1 --until dl_card_DB
snakemake --use-conda --cores 1 --until antismash_download_databases
```

## Singularity / Apptainer Containers

We understand that each HPC is unique. By default OpusTaxa uses conda to manage software environments. On most HPC clusters this works fine, but some systems — particularly those with high-performance parallel filesystems like Lustre (e.g. Pawsey Setonix, NCI Gadi) — have restrictions that cause conda to fail or perform poorly. Conda creates tens of thousands of small files per environment, which can overwhelm a Lustre metadata server, hit inode quotas, and result in corrupted environments that are difficult to diagnose.

Singularity (also called Apptainer on newer systems) solves this by packaging each tool and all its dependencies into a single portable image file (`.sif`). One tool, one file — no inode issues, faster to load, and fully reproducible.

```bash
# Clone the repo on your build machine
git clone https://github.com/yenkaiC/OpusTaxa.git
cd OpusTaxa

conda activate snakemake

# If Singularity/Apptainer is available as a module on your HPC, load it before running
# You would need the equivalent for your HPC, e.g. module load singularity/4.1.0-nompi.
# You can check whether your HPC has it with the following commands:
# module avail 2>&1 | grep -i singularity
# module avail 2>&1 | grep -i apptainer
module load singularity 

# Dry-run to verify everything is configured correctly
snakemake --workflow-profile config/slurm_singularity --dry-run

# Full run
snakemake --workflow-profile config/slurm_singularity

# Enable additional modules - flags work the same as standard runs
snakemake --workflow-profile config/slurm_singularity \
    --config download_sra=true kraken2=true humann=true metaspades=true rgi=true antismash=true
```

> **Note:** Use `--workflow-profile config/slurm_singularity` instead of `config/slurm` when running with containers. Do not mix the two profiles.

## Adjusting Containers for your hpc

OpusTaxa can run tools using either **Singularity/Apptainer containers** or **conda environments**. Which you use depends on your HPC.

The SLURM profile (`config/slurm/config.yaml`) includes a specific bind mount argument:

```yaml
singularity-args: "-B /scratch -B /software"
```

This binds `/scratch` (where your data lives) and `/software` (where Apptainer caches pulled containers) into the container. These paths are specific to certain HPCs — users on other clusters will need to adjust this.

### Using containers on another HPC

If your HPC requires containers, two things need to be updated:

**1. Update the bind mounts in `config/slurm/config.yaml`**

The `-B` flags tell Singularity/Apptainer which directories on the host to make visible inside the container. Replace the Pawsey-specific paths with the paths relevant to your system:

```yaml
# Pawsey Setonix (default)
singularity-args: "-B /scratch -B /software"

# Example for a generic HPC — bind your scratch and data directories
singularity-args: "-B /scratch/yourproject -B /home/yourusername"
```

Enforcing bindmounds via the command line:
```bash
snakemake --workflow-profile config/slurm_singularity \
    --singularity-args "-B /scratch -B /software"
```

At minimum you need to bind whichever directory contains your input data and databases. If unsure, check with your HPC support team.

**2. Building your own containers**

*Build your own `.sif` files*

Container definition files (`.def`) for every tool are available in the [OpusTaxa Containers repository](https://github.com/yenkaiC/OpusTaxa_Containers). Build them on a machine where you have sudo or fakeroot access (not on the HPC login node):

```bash
git clone https://github.com/yenkaiC/OpusTaxa_Containers.git
cd OpusTaxa_Containers

# Build with sudo
sudo apptainer build fastp.sif containers/fastp.def

# Or with fakeroot if sudo is unavailable
apptainer build --fakeroot fastp.sif containers/fastp.def
```

Then copy the `.sif` files to your HPC and update `config/config.yaml` with their paths as shown above.

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


## Monitoring Jobs

```bash
# View your running and pending jobs
squeue -u $(whoami)

# Check a specific job log
cat .snakemake/slurm_logs/rule_metaphlan/<sample>/12345.log
```

