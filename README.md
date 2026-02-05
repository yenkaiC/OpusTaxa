# OpusTaxa: Metagenomic Processing Pipeline
OpusTaxa is a pipeline that streamlines best-practice end-to-end processing of shotgun metagenomic data with various metagenomic tools, from quality control to, host-read removal to taxonomic and funcational profiling. 

<img src="/Misc/OpusTaxa_logo.png" alt="OpusTaxa Logo" title="OpusTaxa Logo" width="250">

## Summary of pipeline
1. Quality Control with [fastp](https://github.com/OpenGene/fastp)
    - Filters out low-quality reads
2. Removes host-reads with [NoHuman](https://github.com/mbhall88/nohuman)
3. Read and output reports on the quality of the sequencesFastQC
    - Conducts [FastQC](https://github.com/s-andrews/FastQC) on the Raw, FastP, and NoHuman sequences
    - Summarises the FastQC quality control statistics with MultiQC
5. Performs Taxonomic classification and/or profiling with
    - [Metaphylan](https://github.com/biobakery/MetaPhlAn)
    - [SingleM](https://wwood.github.io/singlem/)

## Usage
Clone the OpusTaxa Repository
'''
git clone https://github.com/yenkaiC/OpusTaxa.git
'''