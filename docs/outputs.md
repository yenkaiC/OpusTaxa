---
layout: default
title: Output Files
nav_order: 8
---

# Output Files
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Directory Structure

After a full run (all modules enabled), the output tree looks like this:

```
Data/
├── Raw_FastQ/             ← Your input FASTQ files (never modified)
├── FastP/                 ← Quality-trimmed reads
├── NoHuman/               ← Host-filtered reads
│   └── nohuman_summary.tsv
├── MetaPhlAn/
│   ├── {sample}/
│   │   ├── {sample}_profile.txt
│   │   └── {sample}_bowtie.bz2
│   └── table/
│       ├── abundance_all.txt
│       └── abundance_species.txt
├── SingleM/
│   ├── {sample}/
│   │   ├── {sample}_profile.tsv
│   │   ├── {sample}_otu-table.tsv
│   │   ├── {sample}_species_by_site.tsv
│   │   ├── {sample}_longform.tsv
│   │   └── {sample}.spf.tsv
│   └── table/
│       ├── merged_profile.tsv
│       ├── merged_prokaryotic_fraction.tsv
│       └── species_by_site/
├── Kraken2/
│   ├── {sample}/
│   │   ├── {sample}_report.txt
│   │   ├── {sample}_output.txt
│   │   ├── {sample}_bracken.txt
│   │   └── {sample}_bracken_report.txt
│   └── table/
│       └── combined_bracken_species.txt
├── MetaSPAdes/
│   └── {sample}/
│       ├── contigs.fasta
│       └── scaffolds.fasta
├── HUMAnN/
│   ├── genefamilies/{sample}_genefamilies.tsv
│   ├── pathabundance/{sample}_pathabundance.tsv
│   ├── pathcoverage/{sample}_pathcoverage.tsv
│   └── merged/
│       ├── genefamilies_cpm_unstratified.tsv
│       ├── pathabundance_cpm_unstratified.tsv
│       └── pathcoverage_joined_unstratified.tsv
├── RGI/
│   ├── {sample}/contigs/
│   │   ├── {sample}_rgi.txt
│   │   └── {sample}_rgi.json
│   └── table/
│       └── rgi_merged.tsv
├── AntiSMASH/
│   ├── {sample}/
│   │   ├── index.html
│   │   ├── contigs_filtered.gbk
│   │   └── contigs_filtered.json
│   └── table/
│       └── antismash_summary.tsv
├── MLP/
│   ├── load.tsv
│   └── qmp.tsv
├── StrainPhlAn/
│   ├── consensus_markers/
│   ├── db_markers/
│   └── output/{species}/
│       └── RAxML_bestTree.{species}.StrainPhlAn4.tre
└── ProdigalGV/
    ├── {sample}/
    │   ├── {sample}_proteins.faa
    │   ├── {sample}_genes.fna
    │   └── {sample}_genes.gff
    └── table/
        └── prodigal_gv_summary.tsv

Reports/
├── FastQC/
│   ├── Step_1_Raw/
│   ├── Step_2_FastP/
│   └── Step_3_NoHuman/
└── MultiQC/
    ├── raw_multiqc_report.html
    ├── fastp_multiqc_report.html
    └── nohuman_multiqc_report.html
```

---

## Key Per-Cohort Output Files

These are the primary files you will use for downstream analysis — one file per cohort rather than per sample:

| File | Module | Description |
|------|--------|-------------|
| `Data/NoHuman/nohuman_summary.tsv` | NoHuman | Human read removal statistics |
| `Data/MetaPhlAn/table/abundance_all.txt` | MetaPhlAn | Merged taxonomic profiles (all levels) |
| `Data/MetaPhlAn/table/abundance_species.txt` | MetaPhlAn | Species-level profiles only |
| `Data/SingleM/table/merged_profile.tsv` | SingleM | Merged SingleM profiles |
| `Data/SingleM/table/merged_prokaryotic_fraction.tsv` | SingleM | Prokaryotic fraction per sample |
| `Data/Kraken2/table/combined_bracken_species.txt` | Kraken2 | Bracken species abundance table |
| `Data/HUMAnN/merged/genefamilies_cpm_unstratified.tsv` | HUMAnN | Gene family abundances (CPM) |
| `Data/HUMAnN/merged/pathabundance_cpm_unstratified.tsv` | HUMAnN | Pathway abundances (CPM) |
| `Data/HUMAnN/merged/pathcoverage_joined_unstratified.tsv` | HUMAnN | Pathway coverage |
| `Data/RGI/table/rgi_merged.tsv` | RGI | Resistance gene hits across all samples |
| `Data/AntiSMASH/table/antismash_summary.tsv` | AntiSMASH | BGC summary across all samples |
| `Data/MLP/load.tsv` | MLP | Predicted microbial load per sample |
| `Data/MLP/qmp.tsv` | MLP | QMP-corrected abundances |
| `Data/ProdigalGV/table/prodigal_gv_summary.tsv` | Prodigal-GV | Gene prediction statistics |
| `Reports/MultiQC/nohuman_multiqc_report.html` | QC | Aggregated QC report (final reads) |

---

## Log Files

All rule logs are written to `logs/`. On SLURM, job logs go to `logs/slurm/`.

Each rule writes a `.log` file named after the rule and sample, e.g.:
```
logs/metaphlan/sample1.log
logs/nohuman/sample1.log
```

Check log files when a job fails to diagnose the error.
