---
layout: default
title: Databases
nav_order: 5
---

# Databases
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Overview

All databases are downloaded automatically the first time they are needed. Subsequent runs use cached versions. Downloads are tracked by checkpoint files so they are never repeated unless you delete the database directory.

**Total disk space (all databases): ~140 GB**

---

## Database Summary

| Database | Tool | Version | Size | Download Checkpoint |
|----------|------|---------|------|---------------------|
| NoHuman HPRC.r2 | NoHuman | 0.5.0 | ~5.9 GB | `Database/nohuman/HPRC.r2/db/taxo.k2d` |
| MetaPhlAn | MetaPhlAn | vJan25_CHOCOPhlAnSGB_202503 | ~34 GB | `Database/metaphlan/.download_complete` |
| SingleM | SingleM | S5.4.0 GTDB_r226 | ~7 GB | `Database/singlem/S5.4.0.GTDB_r226.metapackage_20250331.smpkg.zb` |
| Kraken2 PlusPF-16 | Kraken2 | 2.1.6 | ~16 GB | `Database/kraken2/.download_complete` |
| HUMAnN ChocoPhlAn | HUMAnN | 3.9 | ~24 GB | `Database/humann/chocophlan/` |
| HUMAnN UniRef90 | HUMAnN | 3.9 | ~23 GB | `Database/humann/uniref/` |
| HUMAnN Utility | HUMAnN | 3.9 | ~5 GB | `Database/humann/utility_mapping/` |
| CARD + WildCARD | RGI | 6.0.5 | ~16.8 GB | `Database/card/card.json` |
| AntiSMASH | AntiSMASH | 8.0.4 | ~9.4 GB | `Database/antismash/.databases_downloaded` |

---

## Per-Database Details

### NoHuman (Human Removal)

- **Source:** HPRC (Human Pangenome Reference Consortium) r2
- **Purpose:** Kraken2-formatted database for host read removal
- **Files:** `taxo.k2d`, `hash.k2d`, `opts.k2d`
- **First-run time:** ~480 min on HPC

### MetaPhlAn

- **Index:** `mpa_vJan25_CHOCOPhlAnSGB_202503`
- **Purpose:** Species-level marker gene database (SGBs — Species-level Genome Bins)
- **First-run time:** up to 1440 min (24 h) — download once; cache persists
- **Checkpoint:** `Database/metaphlan/.download_complete`

### SingleM

- **Package:** `S5.4.0.GTDB_r226.metapackage_20250331.smpkg.zb`
- **Reference taxonomy:** GTDB r226
- **Purpose:** HMM-based marker genes for taxonomic profiling and prokaryotic fraction estimation
- **First-run time:** ~480 min

### Kraken2 PlusPF-16

- **Source:** AWS S3 (`k2_pluspf_16_GB_20251015.tar.gz`)
- **Scope:** Archaea, bacteria, viruses, plasmids, human, UniVec_Core, protozoa, fungi
- **Memory footprint:** Requires 16+ GB RAM during classification
- **Checkpoint:** `Database/kraken2/.download_complete`

### HUMAnN Databases (3 components)

All three components are required for HUMAnN to run:

1. **ChocoPhlAn** — nucleotide gene catalog (~24 GB)
2. **UniRef90** — protein database (~23 GB)
3. **Utility mapping** — pathway maps and metadata (~5 GB)

{: .note }
HUMAnN bypasses nucleotide search and goes directly to protein search. The ChocoPhlAn database is still required for the translated search.

### CARD + WildCARD

- **Sources:**
  - CARD: `https://card.mcmaster.ca/latest/data`
  - WildCARD variants: `https://card.mcmaster.ca/latest/variants`
- **Output:** `Database/card/card.json` + `wildcard/` directory
- **Local index:** Built automatically by RGI after download

{: .warning }
CARD and RGI are licensed for academic and non-commercial use. Verify the [CARD license](https://card.mcmaster.ca/about) before commercial use.

### AntiSMASH

- **Includes:** ClusterBlast, Pfam, TIGRFAM, and other reference databases
- **Checkpoint:** `Database/antismash/.databases_downloaded`

{: .warning }
AntiSMASH is for academic use only. Verify the [AntiSMASH license](https://antismash.secondarymetabolites.org/#!/about) before commercial use.

---

## Pre-downloading Databases

On HPC systems where compute nodes lack internet access, download databases on the login node before submitting jobs:

```bash
# Core (always needed)
snakemake --use-conda --cores 2 \
    Database/nohuman/HPRC.r2/db/taxo.k2d

# MetaPhlAn
snakemake --use-conda --cores 2 \
    Database/metaphlan/.download_complete

# SingleM
snakemake --use-conda --cores 2 \
    "Database/singlem/S5.4.0.GTDB_r226.metapackage_20250331.smpkg.zb"

# Kraken2
snakemake --use-conda --cores 2 \
    Database/kraken2/.download_complete

# HUMAnN (all three)
snakemake --use-conda --cores 2 \
    Database/humann/chocophlan \
    Database/humann/uniref \
    Database/humann/utility_mapping

# CARD + WildCARD
snakemake --use-conda --cores 2 \
    Database/card/card.json

# AntiSMASH
snakemake --use-conda --cores 2 \
    Database/antismash/.databases_downloaded
```

---

## Using a Shared Database Directory

If multiple projects share the same databases, point OpusTaxa at the existing location:

```bash
snakemake --config databaseDirectory=/shared/databases/opustaxa
```

The directory structure must match the layout expected by OpusTaxa (i.e., the same subdirectory names as listed in the checkpoint paths above).
