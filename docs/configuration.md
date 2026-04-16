---
layout: default
title: Configuration
nav_order: 4
---

# Configuration
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Config File

The main configuration file lives at `config/config.yaml`. Every setting can also be overridden on the command line with `--config KEY=VALUE`.

---

## Module Flags

These flags control which analysis modules run. Set to `true` to enable.

| Key | Default | Description |
|-----|---------|-------------|
| `test_mode` | `false` | Use bundled test data from `Misc/Test/Raw_FastQ/` instead of `Data/Raw_FastQ/` |
| `download_sra` | `false` | Download FASTQ files from NCBI SRA using accession IDs in `sra_id.txt` |
| `metaphlan` | `true` | MetaPhlAn 4 taxonomic profiling |
| `singlem` | `true` | SingleM marker gene profiling and prokaryotic fraction estimation |
| `kraken2` | `false` | Kraken2 k-mer classification and Bracken abundance estimation |
| `metaspades` | `false` | MetaSPAdes metagenome assembly |
| `humann` | `false` | HUMAnN 3 functional gene families and pathway profiling |
| `mlp` | `false` | Microbial Load Prediction (requires `metaphlan=true`) |
| `rgi` | `false` | Antibiotic resistance gene identification (requires `metaspades=true`) |
| `antismash` | `false` | Biosynthetic gene cluster detection (requires `metaspades=true`) |
| `strainphlan` | `false` | Strain-level phylogenetics (requires `metaphlan=true`) |
| `prodigal_gv` | `false` | Gene prediction including giant viruses (requires `metaspades=true`) |

**Example — enable Kraken2 and HUMAnN from the command line:**
```bash
snakemake --use-conda --cores 16 --config kraken2=true humann=true
```

---

## StrainPhlAn Species

When `strainphlan=true`, specify one or more SGB (Species-level Genome Bin) identifiers:

```bash
# Single species
snakemake --config strainphlan=true strainphlan_species='["t__SGB1877"]'

# Multiple species
snakemake --config strainphlan=true \
    strainphlan_species='["t__SGB1877","t__SGB6080","t__SGB15341"]'
```

To find which species are present across your samples:
```bash
grep "t__" Data/MetaPhlAn/table/abundance_all.txt | \
    awk -F'\t' '{present=0; for(i=2;i<=NF;i++) if($i>0) present++; if(present>=4) print present, $0}' | \
    sort -rn | head -20
```

This lists the top 20 species present in at least 4 samples — good candidates for strain-level analysis.

---

## Thread Configuration

Default threads per tool (configurable in `config/config.yaml`):

| Tool | Default Threads | Suggested Range |
|------|----------------|----------------|
| `fastp` | 10 | 4–16 |
| `nohuman` | 8 | 4–16 |
| `fastqc` | 8 | 4–8 |
| `metaphlan` | 8 | 4–16 |
| `singlem` | 10 | 4–16 |
| `kraken2` | 8 | 4–16 |
| `humann` | 10 | 8–16 |
| `metaspades` | 12 | 8–32 |
| `rgi` | 10 | 4–16 |
| `antismash` | 16 | 8–32 |

Override a single tool's threads:
```bash
snakemake --config threads.metaspades=32
```

---

## Directory Configuration

All directories are configurable. The defaults assume you run Snakemake from the repository root.

| Key | Default |
|-----|---------|
| `databaseDirectory` | `Database` |
| `inputFastQDirectory` | `Data/Raw_FastQ` |
| `rawFastQDirectory` | `Data/Raw_FastQ` |
| `trimmedFastQDirectory` | `Data/FastP` |
| `nohumanDirectory` | `Data/NoHuman` |
| `metaphlanDirectory` | `Data/MetaPhlAn` |
| `singlemDirectory` | `Data/SingleM` |
| `kraken2Directory` | `Data/Kraken2` |
| `multiQCDirectory` | `Reports/MultiQC` |
| `qcOutputDirectory` | `Reports/FastQC` |
| `metaspadesDirectory` | `Data/MetaSPAdes` |
| `humannDirectory` | `Data/HUMAnN` |
| `mlpDirectory` | `Data/MLP` |
| `rgiDirectory` | `Data/RGI` |
| `antismashDirectory` | `Data/AntiSMASH` |
| `strainphlanDirectory` | `Data/StrainPhlAn` |
| `prodigalGVDirectory` | `Data/ProdigalGV` |
| `logDirectory` | `logs` |
| `slurmLogDirectory` | `logs/slurm` |

**Example — store databases on a separate disk:**
```bash
snakemake --config databaseDirectory=/data/databases
```

---

## AntiSMASH Contig Filter

Short contigs are filtered before AntiSMASH to reduce noise and runtime. The minimum length defaults to 1000 bp and can be changed:

```yaml
# config/config.yaml
antismash_min_contig_length: 1000
```

---

## Container Support

For HPC systems using Singularity, set `use_containers: true` in `config/config.yaml` and provide paths to `.sif` files:

```yaml
use_containers: true
containers:
  fastp: "/software/projects/<project>/<user>/containers/fastp.sif"
  nohuman: "/software/projects/<project>/<user>/containers/nohuman.sif"
  metaphlan: "/software/projects/<project>/<user>/containers/metaphlan.sif"
  # ... (one entry per tool)
```

Pre-built Singularity definition files (`.def`) are provided in `Workflow/containers/`. See [HPC Guide]({% link hpc.md %}) for build instructions.

---

## Full `config.yaml` Reference

```yaml
# ── Directories ──────────────────────────────────────────────
databaseDirectory: Database
inputFastQDirectory: Data/Raw_FastQ
rawFastQDirectory: Data/Raw_FastQ
trimmedFastQDirectory: Data/FastP
nohumanDirectory: Data/NoHuman
metaphlanDirectory: Data/Metaphlan
singlemDirectory: Data/SingleM
kraken2Directory: Data/Kraken2
multiQCDirectory: Reports/MultiQC
qcOutputDirectory: Reports/FastQC
metaspadesDirectory: Data/MetaSPAdes
humannDirectory: Data/HUMAnN
mlpDirectory: Data/MLP
rgiDirectory: Data/RGI
antismashDirectory: Data/AntiSMASH
logDirectory: logs
slurmLogDirectory: logs/slurm
strainphlanDirectory: Data/StrainPhlAn
prodigalGVDirectory: Data/ProdigalGV

# ── Module Flags ─────────────────────────────────────────────
test_mode: false
download_sra: false
metaphlan: true
singlem: true
kraken2: false
metaspades: false
mlp: false
humann: false
rgi: false
antismash: false
strainphlan: false
strainphlan_species: []
prodigal_gv: false

# ── Thread Allocation ────────────────────────────────────────
threads:
  fastp: 10
  nohuman: 8
  fastqc: 8
  metaphlan: 8
  singlem: 10
  kraken2: 8
  humann: 10
  metaspades: 12
  rgi: 10
  antismash: 16

# ── Containers (optional) ────────────────────────────────────
use_containers: false
containers:
  fastp: ""
  nohuman: ""
  metaphlan: ""
  singlem: ""
  kraken2: ""
  humann: ""
  metaspades: ""
  rgi: ""
  antismash: ""
  mlp: ""
  fastqc: ""
  multiqc: ""
  sra: ""
  prodigal_gv: ""
```
