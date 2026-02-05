# OpusTaxa: Metagenomic Processing Pipeline
OpusTaxa is a pipeline that streamlines best-practice end-to-end processing of shotgun metagenomic data with various metagenomic tools, from quality control to, host-read removal to taxonomic and funcational profiling. 

<img src="/Misc/OpusTaxa_logo.png" alt="OpusTaxa Logo" title="OpusTaxa Logo" width="250">

## Summary of pipeline
1. Quality Control with [fastp](https://github.com/OpenGene/fastp)
    - Filters out low-quality reads
2. Removes host-reads with [NoHuman](https://github.com/mbhall88/nohuman)
3. Read and output reports on the quality of the sequencesFastQC
    - Conducts [FastQC](https://github.com/s-andrews/FastQC) on the Raw, and processed FastP and NoHuman sequences
    - Summarises the FastQC quality control statistics with MultiQC
5. Performs Taxonomic classification and/or profiling with
    - [Metaphylan](https://github.com/biobakery/MetaPhlAn)
    - [SingleM](https://wwood.github.io/singlem/)

## Usage
Clone the OpusTaxa Repository
```
git clone https://github.com/yenkaiC/OpusTaxa.git
```

If you haven't already, make sure to install snakemake and activate it for the session
```
conda install bioconda::snakemake
conda activate snakemake
```

Transfer your raw data to the cloned repository following folder '/OpusTaxa/Data/Raw_FastQ'
You should test it on two to three samples before running it on all your samples. 

Your files should be in the following format 
`sample_name_R1_001.fastq.gz` 
(e.g. `12-343567_S2_R1.fastq.gz`, `plzWork_R2.fastq.gz`) or 
`sample_name_1.fastq.gz` 
(e.g. `SRR12345678_1.fastq.gz`, `SRR12345678_2.fastq.gz`), 
the latter will be converted to the earlier format.

### Running on the HPC
Unless you are conducting shallow sequencing (e.g. MiSeq), it is often good to process your files in a high-performance computing (HPC) environment.
To run OpusTaxa on the HPC, you should install Snakemake's executor plugin for slurm (if your HPC runs on slurm).
```
pip install snakemake-executor-plugin-slurm
```
Send jobs to the HPC
```
snakemake --workflow-profile config.slurm.yaml
```
You can also test the runs before sending jobs to slurm
```
snakemake --workflow-profile config.slurm.yaml —dry-run
```