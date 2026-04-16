---
layout: default
title: Quick Start
nav_order: 3
---

# Quick Start
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Minimal Run (Core Modules)

Runs fastp trimming, host removal, FastQC/MultiQC, MetaPhlAn, and SingleM:

```bash
snakemake --use-conda --cores 8
```

---

## Common Scenarios

### Taxonomic profiling only

```bash
snakemake --use-conda --cores 16 \
    --config metaphlan=true singlem=true
```

### Add functional profiling

Requires MetaPhlAn profiles. HUMAnN runs on forward reads only.

```bash
snakemake --use-conda --cores 16 \
    --config metaphlan=true humann=true
```

### Full assembly-based analysis

Enables assembly plus all downstream tools (RGI, AntiSMASH, Prodigal-GV):

```bash
snakemake --use-conda --cores 32 \
    --config metaspades=true rgi=true antismash=true prodigal_gv=true
```

### Everything enabled

```bash
snakemake --use-conda --cores 32 \
    --config \
        metaphlan=true \
        singlem=true \
        kraken2=true \
        metaspades=true \
        humann=true \
        rgi=true \
        antismash=true \
        mlp=true \
        prodigal_gv=true
```

### Download public data from SRA first

Add accession IDs (one per line) to `sra_id.txt`, then:

```bash
snakemake --use-conda --cores 8 \
    --config download_sra=true metaphlan=true singlem=true
```

### Test with bundled test data

```bash
snakemake --use-conda --cores 8 --config test_mode=true
```

---

## HPC / SLURM

Submit all jobs to the scheduler automatically using the bundled SLURM profile:

```bash
conda activate snakemake
snakemake --workflow-profile config/slurm \
    --config metaphlan=true singlem=true
```

{: .note }
Download databases on a login node first if your compute nodes lack internet access. See [HPC Guide]({% link hpc.md %}).

---

## Pre-downloading Databases

To separate database setup from analysis (e.g., on a login node):

```bash
snakemake --use-conda --cores 2 \
    Database/nohuman/HPRC.r2/db/taxo.k2d \
    Database/metaphlan/.download_complete \
    Database/singlem/S5.4.0.GTDB_r226.metapackage_20250331.smpkg.zb
```

See [Databases]({% link databases.md %}) for the full list of database targets.

---

## Useful Snakemake Flags

| Flag | Purpose |
|------|---------|
| `--dry-run` / `-n` | Preview jobs without running them |
| `--cores N` | Use N CPU cores |
| `--use-conda` | Activate per-tool Conda environments |
| `--rerun-incomplete` | Re-run any incomplete jobs from a previous run |
| `--keep-going` | Continue with independent jobs if one fails |
| `--forceall` | Force re-run of all rules |
| `--until RULE` | Stop after completing the specified rule |
| `--config KEY=VALUE` | Override config.yaml settings on the command line |
| `--workflow-profile PATH` | Use a Snakemake workflow profile (e.g., for SLURM) |

---

## Expected Runtime (per sample, 4 GB reads)

| Module | Approx. Time | Peak RAM |
|--------|-------------|----------|
| fastp + NoHuman | 30 min | 32 GB |
| MetaPhlAn | 2–4 h | 50 GB |
| SingleM | 4–8 h | 40 GB |
| Kraken2 | 1–2 h | 64 GB |
| MetaSPAdes | 12–48 h | 100 GB |
| HUMAnN | 8–23 h | 64 GB |
| RGI | 4–16 h | 40 GB |
| AntiSMASH | 12–48 h | 32 GB |

{: .warning }
MetaSPAdes and AntiSMASH have very long runtimes and high memory requirements. Run them on HPC or machines with sufficient resources.
