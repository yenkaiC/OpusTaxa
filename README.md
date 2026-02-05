# OpusTaxa: Metagenomic Processing Pipeline
OpusTaxa is a pipeline that streamlines best-practice end-to-end processing of shotgun metagenomic data with various metagenomic tools, from quality control to, host-read removal to taxonomic and funcational profiling. 

<img src="/Misc/OpusTaxa_logo.png" alt="OpusTaxa Logo" title="OpusTaxa Logo" width="250">

## Summary of pipeline
1. Quality Control with fastp
    - Filters out low-quality reads
2. Removes host-reads with NoHuman
3. Read and output reports on the quality of the sequencesFastQC
    - Conducts FastQC on Raw, FastP, and NoHuman sequences
    - Summarises the FastQC quality control statistics with MultiQC
5. Performs Taxonomic classification and/or profiling with
    - Metaphylan
    - SingleM

## Usage