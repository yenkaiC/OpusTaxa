---
layout: default
title: Prodigal-GV (Gene Prediction)
parent: Modules
nav_order: 13
---

# Prodigal-GV — Gene Prediction
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Overview

Prodigal-GV is an extended version of Prodigal that predicts protein-coding genes in assembled metagenomes, with specific support for **giant viruses** and non-standard genetic codes.

| Attribute | Value |
|-----------|-------|
| Tool | [Prodigal-GV](https://github.com/apcamargo/prodigal-gv) |
| Version | 2.11.0 |
| Config flag | `prodigal_gv` (default: `false`) |
| Requires | `metaspades=true` |
| Rules | `prodigal_gv`, `prodigal_gv_summary` |
| Rule file | `Workflow/rules/prodigal_gv.smk` |
| Default threads | 8 |
| Default RAM | 32 GB |
| Default wall time | 10 h |

---

## Enable

```bash
snakemake --use-conda --cores 16 \
    --config metaspades=true prodigal_gv=true
```

---

## Rules

### `prodigal_gv`

Runs parallelized Prodigal-GV on assembled contigs using `parallel-prodigal-gv.py`.

**Input:** `Data/MetaSPAdes/{sample}/contigs.fasta`

**Output:**
| File | Description |
|------|-------------|
| `Data/ProdigalGV/{sample}/{sample}_proteins.faa` | Predicted protein sequences (FASTA) |
| `Data/ProdigalGV/{sample}/{sample}_genes.fna` | Predicted gene nucleotide sequences (FASTA) |
| `Data/ProdigalGV/{sample}/{sample}_genes.gff` | Gene annotations (GFF3 format) |

Runs in quiet mode (`-q`).

### `prodigal_gv_summary`

Parses GFF files across all samples to summarize gene prediction statistics.

**Output:** `Data/ProdigalGV/table/prodigal_gv_summary.tsv`

| Column | Description |
|--------|-------------|
| `sample` | Sample identifier |
| `total_genes` | Total predicted genes |
| `complete_genes` | Genes with both start and stop codons |
| `partial_genes` | Genes at contig edges (incomplete) |
| `avg_gene_length` | Average gene length (bp) |

---

## Why Prodigal-GV?

Standard Prodigal predicts genes assuming standard bacterial/archaeal genetic codes. Prodigal-GV additionally handles:

- **Giant virus genomes** (Nucleocytoviricota) with unusual codon usage
- Alternative genetic codes used by some viral lineages
- Better sensitivity on short metagenomic contigs

The parallelized wrapper (`parallel-prodigal-gv.py`) splits the contig FASTA across threads for faster processing.

---

## Thread Configuration

```yaml
threads:
  # prodigal_gv uses the value from prodigal_gv rule (default 8)
```

Override:
```bash
snakemake --config threads.prodigal_gv=16
```
