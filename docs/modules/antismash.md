---
layout: default
title: AntiSMASH (BGCs)
parent: Modules
nav_order: 10
---

# AntiSMASH — Biosynthetic Gene Cluster Detection
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Overview

AntiSMASH identifies and annotates biosynthetic gene clusters (BGCs) — genomic regions encoding the biosynthesis of secondary metabolites such as polyketides, non-ribosomal peptides, terpenes, and more.

| Attribute | Value |
|-----------|-------|
| Tool | [AntiSMASH](https://antismash.secondarymetabolites.org) |
| Version | 8.0.4 |
| Database | ~9.4 GB (ClusterBlast, Pfam, TIGRFAM) |
| Config flag | `antismash` (default: `false`) |
| Requires | `metaspades=true` |
| Rules | `antismash_download_databases`, `filter_contigs`, `antismash_contigs`, `antismash_summary_table` |
| Rule file | `Workflow/rules/antismash.smk` |
| Default threads | 16 |
| Default RAM | 32 GB |
| Default wall time | 48 h |

---

## Enable

```bash
snakemake --use-conda --cores 32 \
    --config metaspades=true antismash=true
```

{: .warning }
AntiSMASH is for **academic use only**. Review the [AntiSMASH license](https://antismash.secondarymetabolites.org/#!/about) before commercial use.

---

## Rules

### `antismash_download_databases`

Downloads AntiSMASH reference databases. Checkpoint: `Database/antismash/.databases_downloaded`.

### `filter_contigs`

Short contigs are filtered before AntiSMASH to reduce noise and runtime.

**Default minimum length: 1000 bp**

```yaml
# config/config.yaml
antismash_min_contig_length: 1000
```

**Input:** `Data/MetaSPAdes/{sample}/contigs.fasta`
**Output:** `Data/AntiSMASH/{sample}/contigs_filtered.fasta`

Log output records how many contigs were kept vs. filtered.

### `antismash_contigs`

Runs the full AntiSMASH analysis.

Settings:
- Taxon: bacteria
- Gene finding: `prodigal-m` (metagenomic Prodigal mode)

**Input:** Filtered contigs + AntiSMASH databases

**Output:**
| File | Description |
|------|-------------|
| `Data/AntiSMASH/{sample}/index.html` | Interactive HTML report |
| `Data/AntiSMASH/{sample}/contigs_filtered.gbk` | GenBank-format annotation |
| `Data/AntiSMASH/{sample}/contigs_filtered.json` | Full JSON results |
| `Data/AntiSMASH/{sample}/.antismash_complete` | Completion marker |

Open `index.html` in a browser for a visual overview of detected BGCs.

### `antismash_summary_table`

Parses all JSON outputs across samples into a flat summary TSV.

**Output:** `Data/AntiSMASH/table/antismash_summary.tsv`

---

## Summary Table Columns

| Column | Description |
|--------|-------------|
| `sample` | Sample identifier |
| `contig` | Contig ID |
| `region_start` | BGC start coordinate |
| `region_end` | BGC end coordinate |
| `region_length` | BGC length (bp) |
| `bgc_type` | BGC type (e.g., `NRPS`, `PKS`, `terpene`, `RiPP`) |
| `contig_edge` | Whether the BGC is truncated at a contig edge |
| `most_similar_known_bgc` | Closest match in the MIBiG reference database |

---

## BGC Type Reference

Common BGC types you may encounter:

| Type | Secondary Metabolite |
|------|---------------------|
| `PKS` | Polyketides (e.g., erythromycin, rapamycin) |
| `NRPS` | Non-ribosomal peptides (e.g., vancomycin) |
| `terpene` | Terpenes |
| `RiPP` | Ribosomally synthesized and post-translationally modified peptides |
| `betalactone` | Beta-lactone-containing metabolites |
| `sactipeptide` | Sactipeptides |
