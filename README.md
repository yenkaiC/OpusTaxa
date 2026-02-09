# OpusTaxa: Metagenomic Processing Pipeline
OpusTaxa is a pipeline that streamlines best-practice end-to-end processing of shotgun metagenomic data with various metagenomic tools, from quality control to, host-read removal to taxonomic and funcational profiling. 

<img src="/Misc/OpusTaxa_logo.png" alt="OpusTaxa Logo" title="OpusTaxa Logo" width="250">

## Summary of pipeline
1. **Quality Control** with [fastp](https://github.com/OpenGene/fastp)
    - Filters out low-quality reads
2. **Host Read Removal** with [NoHuman](https://github.com/mbhall88/nohuman)
3. **Quality Reports** with [FastQC](https://github.com/s-andrews/FastQC)
    - Quality control reports at each step (raw, trimmed and filter)
    - Aggregates FastQC reports with [MultiQC](https://github.com/MultiQC/MultiQC)
5. **Taxonomic Profiling** with
    - [Metaphylan](https://github.com/biobakery/MetaPhlAn)
    - [SingleM](https://wwood.github.io/singlem/)

## Quick Start
```bash
# 1. Clone the repository
git clone https://github.com/yenkaiC/OpusTaxa.git
cd OpusTaxa

# 2. Create and activate Snakemake environment
conda create -n snakemake -c conda-forge -c bioconda snakemake
conda activate snakemake

# 3. Test with dry-run
snakemake --use-conda --dry-run --cores 1
```

## Usage
### 1. Prepare Input Data

Place your paired-end FASTQ files in `Data/Raw_FastQ/`:<br>
(and remove the test sample files already in folder)
**Delete** `sra_id.txt` file if you are not using it. 
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

**Note:** Start with 2-3 samples to test before running your full dataset.

### 2. Configure Settings (Optional)

Edit `config/config.yaml` to customize:
- Output directories
- Resource requirements
- Tool-specific parameters

### 3. Run the Pipeline

**Local execution:**
```bash
# Dry-run to check everything
snakemake --use-conda --dry-run --cores 8

# Actual Run
snakemake --use-conda --cores 8

# Run with SingleM, and without MetaPhlAn
snakemake --use-conda --cores 8 --config metaphlan=false singlem=true
```

### 4. Access Results

Results are organized in the `Data/` and `Reports/` directories:
```
OpusTaxa/
├── Data/
│   ├── FastP/              # Quality-trimmed reads
│   ├── NoHuman/            # Host-filtered reads
│   ├── MetaPhlAn/          # Taxonomic profiles
│   └── SingleM/            # OTU tables & Microbial Fractions
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

## Resource Requirements

### Minimum (for testing)
- **CPU:** 4 cores
- **RAM:** 16 GB
- **Storage:** 100 GB

### Recommended (for production)
- **CPU:** 8+ cores
- **RAM:** 32+ GB
- **Storage:** 500 GB (depends on dataset size)

### Database Sizes
- NoHuman: ~6.3 GB (As of February 2026)
- MetaPhlAn: ~36 GB (As of February 2026)
- SingleM: ~7.5 GB (Version S5.4.0)

Databases are downloaded automatically on first run.