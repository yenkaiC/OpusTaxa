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
### Step 1a. Clone the OpusTaxa Repository
```
git clone https://github.com/yenkaiC/OpusTaxa.git
```

### Step 1b. Install and Activate Snakemake
If you haven't already, make sure to install and activate it for the session
```
conda install bioconda::snakemake
conda activate snakemake
```

### Step 2a. Transfer Raw Data to Corresponding Directory
Transfer your raw data to the cloned repository following folder <br /> 
```/OpusTaxa/Data/Raw_FastQ``` <br />
You should test it on two to three samples, or run the sample data in the directory before running it on all your samples. 

### Step 2b. Correct File Format
Your files should be in the following format <br />
`sample_name_R1_001.fastq.gz` <br />
(e.g. `12-343567_S2_R1.fastq.gz`, `plzWork_R2.fastq.gz`) or <br />
`sample_name_1.fastq.gz` <br />
(e.g. `SRR12345678_1.fastq.gz`, `SRR12345678_2.fastq.gz`), 
the latter will be converted to the earlier format.

### Step 3: Run OpusTaxa
To run and test your samples in OpusTaxa, type ```snakemake --use-conda``` into the terminal once you are in the OpusTaxa directory. You can specify ```--dry-run``` to check that everything seems to be working prior to committing the run.
```
snakemake --cores 1 --use-conda --dry-run
```
```
snakemake --cores 8 --use-conda
```