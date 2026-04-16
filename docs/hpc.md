---
layout: default
title: HPC Guide
nav_order: 6
---

# HPC Guide
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## SLURM Workflow Profile

OpusTaxa ships with a ready-to-use SLURM profile at `config/slurm/config.yaml`. Use it with the `--workflow-profile` flag:

```bash
conda activate snakemake
snakemake --workflow-profile config/slurm \
    --config metaphlan=true singlem=true
```

### SLURM Profile Settings

`config/slurm/config.yaml`:

```yaml
executor: slurm
jobs: 50                    # Maximum concurrent jobs

default-resources:
  mem_mb: 24000             # 24 GB default per job
  runtime: 480              # 8 hours default

rerun-incomplete: true      # Re-run jobs that failed mid-way
restart-times: 3            # Retry failed jobs up to 3 times
use-conda: true
```

Each Snakemake rule specifies its own `resources` (memory, runtime, threads), so the SLURM executor automatically requests the appropriate allocation for every job.

---

## Singularity Containers

On HPC systems with Lustre shared filesystems, Conda environments can suffer from inode limits and slow I/O. Singularity containers are the recommended alternative.

### Step 1 — Build the Containers

Definition files (`.def`) are provided in `Workflow/containers/`. Build them using the helper script:

```bash
cd Workflow/containers
bash build_containers.sh
```

This requires Singularity/Apptainer and root (or `fakeroot`) on the build node.

### Step 2 — Update `config.yaml`

```yaml
use_containers: true
containers:
  fastp:      "/path/to/containers/fastp.sif"
  nohuman:    "/path/to/containers/nohuman.sif"
  metaphlan:  "/path/to/containers/metaphlan.sif"
  singlem:    "/path/to/containers/singlem.sif"
  kraken2:    "/path/to/containers/kraken2.sif"
  humann:     "/path/to/containers/humann.sif"
  metaspades: "/path/to/containers/metaspades.sif"
  rgi:        "/path/to/containers/rgi.sif"
  antismash:  "/path/to/containers/antismash.sif"
  mlp:        "/path/to/containers/mlp.sif"
  fastqc:     "/path/to/containers/fastqc.sif"
  multiqc:    "/path/to/containers/multiqc.sif"
  sra:        "/path/to/containers/sra.sif"
  prodigal_gv: "/path/to/containers/prodigal-gv.sif"
```

### Step 3 — Run with the Singularity Profile

```bash
snakemake --workflow-profile config/slurm_singularity \
    --config metaphlan=true singlem=true
```

---

## Downloading Databases on Login Nodes

Most HPC compute nodes do not have outbound internet access. Download all required databases on the login node before submitting analysis jobs.

```bash
# Activate the snakemake environment first
conda activate snakemake

# Download databases one at a time (or run in a screen/tmux session)
snakemake --use-conda --cores 2 Database/nohuman/HPRC.r2/db/taxo.k2d
snakemake --use-conda --cores 2 Database/metaphlan/.download_complete
snakemake --use-conda --cores 2 "Database/singlem/S5.4.0.GTDB_r226.metapackage_20250331.smpkg.zb"
```

{: .tip }
Run database downloads inside `screen` or `tmux` so they survive session disconnects.

---

## Resource Allocation

Each rule declares its own resource requirements. Here is a summary of the most demanding jobs — ensure your cluster has nodes large enough:

| Rule | RAM | Threads | Wall Time |
|------|-----|---------|-----------|
| `remove_human_reads` | 32 GB | 8 | 8 h |
| `metaphlan` | 50 GB | 8 | 12 h |
| `singlem_profile` | 40 GB | 10 | 23 h |
| `kraken2` | 64 GB | 8 | 8 h |
| `metaspades` | 100 GB | 12 | 48 h |
| `humann` | 64 GB | 10 | 23 h |
| `rgi_contigs` | 40 GB | 10 | 16 h |
| `antismash_contigs` | 32 GB | 16 | 48 h |

To override the default thread count in SLURM mode, edit `config/config.yaml`:

```yaml
threads:
  metaspades: 32   # Use 32 threads on large-memory nodes
  antismash: 32
```

---

## Troubleshooting on HPC

### Jobs stay pending
Check that the requested resources (RAM, time) do not exceed what your cluster's largest partition can provide. Adjust `threads` and resource limits in `config/config.yaml`.

### Conda environments fail to build
Use Singularity containers instead (see above) or pre-build Conda environments on a node with internet access and point Snakemake at the cached `.snakemake/conda/` directory.

### Database downloads fail on compute nodes
Download databases on a login node first (see section above).

### SLURM job arrays hit submission limits
Reduce `jobs: 50` in `config/slurm/config.yaml` to a value within your cluster's per-user submission limit.
