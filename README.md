<img src="/Misc/OpusTaxa_logo.png" alt="OpusTaxa Logo" title="OpusTaxa Logo" width="250">

# OpusTaxa: Streamlining Metagenome Discoveries
OpusTaxa is an easy‑to‑use pipeline that helps you process shotgun metagenomic data from raw reads to final results. Simply provide your FASTQ files or SRA IDs, and it handles the rest: downloading data and databases, performing quality checks, removing human reads, profiling the microbiome, assembling the metagenome, and running functional analysis. Results are saved as clean tables ready for downstream exploration. OpusTaxa delivers a clear, reproducible, best‑practice workflow without requiring advanced coding or bioinformatics experience.

OpusTaxa has built‑in integration with the Sequence Read Archive (SRA) API, which makes it straightforward to reanalyse published datasets alongside your own, and every tool can be toggled on or off.

## Summary of pipeline
1. **Public Dataset Downloading** with [SRA Toolkit](https://github.com/ncbi/sra-tools)
    - Parallel downloading
    - Parallel compression with [pigz](https://github.com/madler/pigz)
    - Or provide your own local files!
2. **Quality Control** with [fastp](https://github.com/OpenGene/fastp)
    - Filters out low-quality reads
3. **Host Read Removal** with [NoHuman](https://github.com/mbhall88/nohuman)
4. **Quality Reports** with [FastQC](https://github.com/s-andrews/FastQC)
    - Quality control reports at each step (raw, trimmed and filter)
    - Aggregates FastQC reports with [MultiQC](https://github.com/MultiQC/MultiQC)
5. **Taxonomic Profiling** with
    - [Metaphylan](https://github.com/biobakery/MetaPhlAn)
    - [SingleM](https://wwood.github.io/singlem/)
    - [Kraken2](https://github.com/DerrickWood/kraken2) and [Bracken](https://github.com/jenniferlu717/Bracken)
6. **Metagenomic Assembly** with [MetaSPAdes](https://github.com/ablab/spades)
7. **Functional Profiling** with
    - [HUMAnN 3.9](https://huttenhower.sph.harvard.edu/humannn)
    - [RGI (Resistance Gene Identifier)](https://github.com/arpcard/rgi/tree/master)

## Quick Start
```bash
# 1. Clone the repository
git clone https://github.com/yenkaiC/OpusTaxa.git
cd OpusTaxa

# 2. Create and activate Snakemake environment
conda create -n snakemake -c conda-forge -c bioconda snakemake
conda activate snakemake

# 3. Test with dry-run (does not download, only checks whether the operation will run correctly)
snakemake --use-conda --dry-run --cores 1
```

## Usage
### 1. Prepare Input Data

Place your paired-end FASTQ files in `OpusTaxa/Data/Raw_FastQ/`:<br>
**Input, provide, or replace** your SRA IDs into `sra_id.txt` file if you plan on using it, one SRA ID per line. 
```bash
Data/Raw_FastQ/
├── sample1_R1_001.fastq.gz
├── sample1_R2_001.fastq.gz
├── sample2_R1_001.fastq.gz
└── sample2_R2_001.fastq.gz
```

**Supported filename formats:**
- `{sample}_R1_001.fastq.gz` / `{sample}_R2_001.fastq.gz` (Illumina format)
- `{sample}_1.fastq.gz` / `{sample}_2.fastq.gz` (SRA format - auto-converts to Illumina format)

**Note / Option:** Start with 2-3 samples to test before running your full dataset. If the sample has already been processed, OpusTaxa will recognise it and will not re-run. 

### 2. Configure Settings (Optional)

Edit `config/config.yaml` to customize:
- Output directories
- Resource requirements
- Tool-specific parameters

### 3. Run the Pipeline

**Local execution:**
```bash
# Dry-run as initial safety check
snakemake --use-conda --dry-run --cores 8 

## Actual Run
# By default, SingleM and MetaPhlAn are on, everything else is off
snakemake --use-conda --cores 8

# Run with SingleM, and without MetaPhlAn
snakemake --use-conda --cores 8 --config metaphlan=false singlem=true

# Run with SRA integration (off by default)
snakemake --use-conda --cores 8 --config download_sra=true

# Run with test files (off by default)
snakemake --use-conda --cores 8 --config test_mode=true

# Additional config commands
snakemake --use-conda --cores 16 --config humann=true metaspades=true kraken2=true rgi=true
```

### 4. Access Results

Results are organised in the `Data/` and `Reports/` directories:
The tables from MetaPhlAn, SingleM, Kraken2, and HUMAnN are abundances merged across all samples
```
OpusTaxa/
├── Data/
│   ├── Raw_FastQ/          # Raw reads
│   ├── FastP/              # Quality-trimmed reads
│   ├── NoHuman/            # Host-filtered reads
│   ├── MetaPhlAn/          
│   │   ├── Table/          # Relative abundance table
│   ├── SingleM/            # Microbial Fractions
│   │   ├── Table/          # Profile tables in different taxonomic orders
│   ├── Kraken2/            
│   │   ├── Table/          # Bracken table (relative-abundance)
│   ├── HUMAnN/
│   │   ├── merged/         # Abundance tables of gene-families and pathways (normalised, stratified and unstratified)
│   ├── MetaSPAdes/         # Metagenome Assemblies
│   └── RGI/                # Antibiotic Resistance Genes
└── Reports/
    ├── FastQC/             # Individual QC reports
    │   ├── Step_1_Raw/
    │   ├── Step_2_FastP/
    │   └── Step_3_NoHuman/
    └── MultiQC/            # Aggregated reports
        ├── raw_multiqc_report.html
        ├── fastp_multiqc_report.html
        └── nohuman_multiqc_report.html
```

## Running on an HPC (SLURM)

OpusTaxa supports SLURM-managed HPC clusters via the Snakemake SLURM executor plugin. In this mode, Snakemake runs on the **login/home/entry node** and automatically submits each step as a separate SLURM job.

### Prerequisites

Install the SLURM executor plugin in your Snakemake environment:
```bash
conda activate snakemake
pip install snakemake-executor-plugin-slurm
```
### Running the Pipeline

**Important:** Always run Snakemake from the **home node**, not inside an `sbatch` job. Snakemake needs access to the SLURM controller to submit jobs, which is typically unavailable from compute nodes.

Use `screen`, `tmux`, or `nohup` to keep the process running if your SSH session disconnects:
```bash
cd OpusTaxa

# Option 1: Using screen
screen -S opustaxa
conda activate snakemake
snakemake --workflow-profile config/slurm
# Detach: Ctrl+A, then D | Reattach: screen -r opustaxa

# Option 2: Using tmux
tmux new -s opustaxa
conda activate snakemake
snakemake --workflow-profile config/slurm
# Detach: Ctrl+B, then D | Reattach: tmux attach -t opustaxa
```

Dry-run first to verify everything is configured correctly:
```bash
snakemake --workflow-profile config/slurm --dry-run
```

Pipeline flags work the same as local execution:
```bash
snakemake --workflow-profile config/slurm --config download_sra=true metaphlan=true singlem=true
```

## Resource Requirements

### Minimum (for testing)
- **CPU:** 4 cores
- **RAM:** 16 GB
- **Storage:** 100 GB

### Recommended (for production)
- **CPU:** 8+ cores
- **RAM:** 40+ GB (80 GB for MetaSPAdes, 64GB for HUMAnN)
- **Storage:** 500 GB (depends on dataset size)

### Database Size (Uncompressed)
- NoHuman: ~6.3 GB (As of February 2026)
- MetaPhlAn: ~36 GB (As of February 2026)
- SingleM: ~7.5 GB ([Version S5.4.0](https://zenodo.org/records/15232972))
- HUMAnN: ~55.6 GB (HUMAnN 3.9)
- Kraken2: 16.1 GB ([PlusPF-16](https://benlangmead.github.io/aws-indexes/k2))
- RGI: ~16.8 GB (As of February 2026 [latest](https://card.mcmaster.ca/download))

### Things to note
OpusTaxa currently only accepts paired reads. However, we've configured HUMAnN to run only on the forward read.
Databases for the corresponding tool are downloaded automatically on first run (not including dry-tools).