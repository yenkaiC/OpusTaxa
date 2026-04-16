---
layout: default
title: StrainPhlAn
parent: Modules
nav_order: 12
---

# StrainPhlAn — Strain-Level Phylogenetics
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Overview

StrainPhlAn reconstructs strain-level phylogenies for specific species by extracting consensus marker sequences from MetaPhlAn bowtie2 alignments and building maximum-likelihood trees with RAxML. This enables fine-grained strain tracking, e.g., for FMT (fecal microbiota transplantation) donor-recipient studies.

| Attribute | Value |
|-----------|-------|
| Tool | StrainPhlAn (bundled with MetaPhlAn) |
| Tree inference | RAxML |
| Config flag | `strainphlan` (default: `false`) |
| Requires | `metaphlan=true` |
| Rules | `strainphlan_sample2markers`, `strainphlan_extract_markers`, `strainphlan` |
| Rule file | `Workflow/rules/strainphlan.smk` |
| Default threads | 8 |
| Default RAM | 32 GB |

---

## Enable

```bash
snakemake --use-conda --cores 16 \
    --config metaphlan=true strainphlan=true \
    strainphlan_species='["t__SGB1877","t__SGB6080"]'
```

You must provide at least one SGB identifier. See [Finding Species IDs](#finding-species-ids) below.

---

## Rules

### `strainphlan_sample2markers`

Extracts consensus marker sequences from MetaPhlAn bowtie2 alignments for each sample.

**Input:** `Data/MetaPhlAn/{sample}/{sample}_bowtie.bz2`

**Output:** Per-sample marker directory `Data/StrainPhlAn/consensus_markers/{sample}/`

Uses `sample2markers.py` from the MetaPhlAn toolkit.

### `strainphlan_extract_markers`

Extracts reference marker sequences for each target species.

**Input:** SGB species ID (e.g., `t__SGB1877`)

**Output:** `Data/StrainPhlAn/db_markers/{species}.fna`

Uses `extract_markers.py` from the MetaPhlAn toolkit.

### `strainphlan`

Builds a strain-level phylogenetic tree for each species.

**Input:**
- Sample marker files for all samples
- Reference marker FASTA for the target species

**Output:** `Data/StrainPhlAn/output/{species}/RAxML_bestTree.{species}.StrainPhlAn4.tre`

Settings: PhyloPhlAn mode `accurate`, RAxML tree inference.

---

## Finding Species IDs

SGB identifiers use the `t__` prefix (SGB level). To find which species are present in enough samples to build a reliable tree:

```bash
grep "t__" Data/MetaPhlAn/table/abundance_all.txt | \
    awk -F'\t' '{
        present=0;
        for(i=2; i<=NF; i++) if($i>0) present++;
        if(present>=4) print present, $0
    }' | \
    sort -rn | head -20
```

This lists species present in at least 4 samples. A minimum of 4 samples is typically needed for a meaningful phylogenetic tree.

Example output:
```
12  t__SGB1877|...    0.0    5.2    ...
 9  t__SGB6080|...    1.1    0.0    ...
```

Use the `t__SGB####` identifiers (without the `|` suffix) in your config.

---

## Interpreting the Tree

The output `.tre` file is a Newick-format phylogenetic tree. Visualise it with:

- [iTOL](https://itol.embl.de/) — online, interactive
- [FigTree](https://github.com/rambaut/figtree) — desktop application
- R `ape` / `ggtree` packages — programmatic

Samples clustering together on the tree carry closely related strains. Tight clustering between a donor and recipient in FMT studies suggests successful strain engraftment.
