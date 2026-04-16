---
layout: default
title: FAQ & Troubleshooting
nav_order: 10
---

# FAQ & Troubleshooting
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## General

### My samples are not being detected

Check that your FASTQ files are in `Data/Raw_FastQ/` (or the directory set by `inputFastQDirectory`) and that they follow one of the supported naming conventions:

| Format | Example |
|--------|---------|
| Illumina bcl2fastq (with lane) | `sample_S1_L001_R1_001.fastq.gz` |
| Illumina (no lane) | `sample_S1_R1_001.fastq.gz` |
| Standard | `sample_R1_001.fastq.gz` |
| Simple paired | `sample_R1.fastq.gz` |
| SRA / ENA | `sample_1.fastq.gz` |
| Dot-separated (R) | `sample.R1.fastq.gz` |
| Dot-separated (number) | `sample.1.fastq.gz` |

Run `snakemake --dry-run` to see which samples Snakemake detects.

### Can I use single-end reads?

No. OpusTaxa requires **paired-end reads**. All tools in the pipeline are configured for paired-end input.

### How do I re-run a specific sample?

Use `--forcerun` with the rule name:
```bash
snakemake --use-conda --cores 8 --forcerun metaphlan
```

Or target a specific output file:
```bash
snakemake --use-conda --cores 8 \
    Data/MetaPhlAn/sample1/sample1_profile.txt
```

### How do I resume a failed run?

Snakemake automatically detects incomplete outputs and re-runs only the necessary steps. Simply re-run the same command. If jobs were partially written, add `--rerun-incomplete`:

```bash
snakemake --use-conda --cores 8 --rerun-incomplete
```

---

## Resources and Performance

### MetaSPAdes ran out of memory

MetaSPAdes requires up to 100 GB of RAM for complex communities. Options:
1. Run on a high-memory node on HPC
2. Reduce the SPAdes `--memory` flag (edit `Workflow/rules/metaspades.smk`)
3. Pre-filter reads more aggressively (e.g., increase fastp quality threshold)

### HUMAnN is very slow

HUMAnN can take 8–23 hours per sample. This is expected for deep metagenomes. Ensure you have at least 10 threads and 64 GB RAM allocated. On HPC, let it run as a long SLURM job.

### Database download timed out

Increase the wall time for the database download rule in the SLURM config, or download databases manually on the login node (see [Databases]({% link databases.md %})).

---

## Module-Specific

### MetaPhlAn shows zero abundance for all species

- Confirm the database downloaded correctly: `ls Database/metaphlan/`
- Check the log file: `logs/metaphlan/{sample}.log`
- Verify the reads are not over-trimmed or empty after host removal

### HUMAnN fails with "No MetaPhlAn hits"

HUMAnN uses the MetaPhlAn species profile to guide alignment. If MetaPhlAn returns no hits (very low biomass or unusual community), HUMAnN will fall back to translated search only, which may increase runtime significantly.

### RGI returns no hits

- Check `Data/MetaSPAdes/{sample}/contigs.fasta` has contigs (not empty)
- Confirm the CARD database loaded correctly: `ls Database/card/`
- Check the log: `logs/rgi/{sample}.log`
- `Loose` cut-off hits increase sensitivity at the cost of false positives

### StrainPhlAn tree has very few samples

Not all samples will have sufficient coverage of every species. StrainPhlAn requires enough reads aligning to the species' markers. Species present in fewer samples produce less informative trees. Use the grep command in [StrainPhlAn docs]({% link modules/strainphlan.md %}) to find well-covered species.

### MLP gives unexpected values

MLP was trained on faecal samples. For non-faecal sample types (saliva, skin, environmental), the predicted load may not be reliable.

---

## HPC / SLURM

### Jobs fail immediately on compute nodes

Most likely cause: compute nodes lack internet access and a rule is trying to download a database. Pre-download all databases on the login node first (see [HPC Guide]({% link hpc.md %})).

### Conda environments fail to build on shared filesystems

Lustre and other parallel filesystems can cause inode exhaustion when building many Conda environments. Use Singularity containers instead — see [HPC Guide]({% link hpc.md %}).

### SLURM jobs exceed their time limit

Increase the `runtime` for specific rules in `config/slurm/config.yaml`:
```yaml
set-resources:
  - "metaspades:runtime=5760"   # 4 days
  - "antismash_contigs:runtime=5760"
```

---

## Getting Help

If your issue is not covered here, please open an issue on GitHub:

[github.com/yenkaiC/OpusTaxa/issues](https://github.com/yenkaiC/OpusTaxa/issues)

Include:
- The command you ran
- The Snakemake version (`snakemake --version`)
- The relevant log file from `logs/`
- Your `config/config.yaml`
