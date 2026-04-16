---
layout: default
title: RGI (Resistance Genes)
parent: Modules
nav_order: 9
---

# RGI — Antibiotic Resistance Gene Identification
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Overview

RGI (Resistance Gene Identifier) detects antibiotic resistance genes in assembled contigs using the CARD (Comprehensive Antibiotic Resistance Database) and WildCARD variant databases.

| Attribute | Value |
|-----------|-------|
| Tool | [RGI](https://github.com/arpcard/rgi) |
| Version | 6.0.5 |
| Database | CARD + WildCARD (~16.8 GB) |
| Config flag | `rgi` (default: `false`) |
| Requires | `metaspades=true` |
| Rules | `dl_card_DB`, `rgi_contigs`, `rgi_merge_tables` |
| Rule file | `Workflow/rules/rgi.smk` |
| Default threads | 10 |
| Default RAM | 40 GB |
| Default wall time | 16 h |

---

## Enable

```bash
snakemake --use-conda --cores 16 \
    --config metaspades=true rgi=true
```

{: .warning }
CARD is licensed for **academic and non-commercial use only**. Review the [CARD license](https://card.mcmaster.ca/about) before commercial use.

---

## Rules

### `dl_card_DB`

Downloads and indexes both CARD and WildCARD databases:
- CARD: `https://card.mcmaster.ca/latest/data`
- WildCARD: `https://card.mcmaster.ca/latest/variants`

Builds a local RGI index from the downloaded files.

**Output:**
- `Database/card/card.json`
- `Database/card/wildcard/` (variant sequences and indexes)

### `rgi_contigs`

Searches assembled contigs against the CARD database using DIAMOND alignment.

**Input:** `Data/MetaSPAdes/{sample}/contigs.fasta`

**Output:**
| File | Description |
|------|-------------|
| `Data/RGI/{sample}/contigs/{sample}_rgi.txt` | Tab-separated predictions |
| `Data/RGI/{sample}/contigs/{sample}_rgi.json` | Full JSON output with detailed model hits |

Settings: `--input_type contig`, `--alignment_tool DIAMOND`, `--local` (uses CARD local index).

### `rgi_merge_tables`

Merges per-sample RGI results into a single cohort table.

**Output:** `Data/RGI/table/rgi_merged.tsv`

A `sample` column is prepended to each row. The script logs merge statistics (number of hits per sample, total).

---

## Key Output Columns

The `_rgi.txt` file contains one row per resistance gene hit:

| Column | Description |
|--------|-------------|
| `Best_Hit_ARO` | Best-matching ARO (Antibiotic Resistance Ontology) term |
| `ARO` | ARO accession number |
| `Resistance_Mechanism` | Mechanism (e.g., antibiotic efflux, target alteration) |
| `AMR_Gene_Family` | Gene family (e.g., MCR phosphoethanolamine transferase) |
| `Drug_Class` | Antibiotic class(es) |
| `Cut_Off` | RGI confidence: `Perfect`, `Strict`, or `Loose` |
| `Best_Identities` | Amino acid identity to best CARD match |
| `CARD_Protein_Sequence_ID` | CARD reference sequence |

Filter on `Cut_Off` to control false positives: `Perfect` and `Strict` hits are the most reliable.
