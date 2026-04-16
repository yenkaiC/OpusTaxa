---
layout: default
title: QC (FastQC / MultiQC)
parent: Modules
nav_order: 3
---

# QC — FastQC and MultiQC
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Overview

Quality control reports are generated at three stages of the pipeline using FastQC and aggregated into MultiQC reports. QC runs automatically alongside the core pre-processing steps.

| Tool | Version |
|------|---------|
| [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) | 0.12.1 |
| [MultiQC](https://multiqc.info) | 1.33 |

---

## Three QC Stages

| Stage | Input | Output Directory |
|-------|-------|-----------------|
| Step 1 — Raw reads | `Data/Raw_FastQ/` | `Reports/FastQC/Step_1_Raw/` |
| Step 2 — Post-trimming | `Data/FastP/` | `Reports/FastQC/Step_2_FastP/` |
| Step 3 — Post-host removal | `Data/NoHuman/` | `Reports/FastQC/Step_3_NoHuman/` |

Running QC at all three stages allows you to assess the effect of each pre-processing step.

---

## Rules

| Rule | Tool | Input | Output |
|------|------|-------|--------|
| `raw_qc` | FastQC | Raw FASTQ | `Step_1_Raw/` HTML + ZIP per read |
| `fastp_qc` | FastQC | Trimmed FASTQ | `Step_2_FastP/` HTML + ZIP per read |
| `nohuman_qc` | FastQC | Decontaminated FASTQ | `Step_3_NoHuman/` HTML + ZIP per read |
| `multi_qc` | MultiQC | All FastQC ZIP files | 3 × aggregated HTML reports |

---

## MultiQC Reports

Three aggregated HTML reports are written to `Reports/MultiQC/`:

| File | Covers |
|------|--------|
| `raw_multiqc_report.html` | Raw read quality |
| `fastp_multiqc_report.html` | Post-trimming quality |
| `nohuman_multiqc_report.html` | Post-host-removal quality |

Open these in a browser for an interactive summary across all samples.

---

## Thread Configuration

```yaml
# config/config.yaml
threads:
  fastqc: 8
```
