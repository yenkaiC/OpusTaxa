## Read SRA IDs from file
import os

# Read SRA IDs from the file
with open("sra_id.txt", "r") as f:
    SRA_IDS = [line.strip() for line in f if line.strip()]

## Download FastQ File from SRA
rule SRA_downloader:
    output:
        r1 = temp(input_dir + "/{sra_id}_1.fastq"),  # temp() marks for auto-deletion after compression
        r2 = temp(input_dir + "/{sra_id}_2.fastq")
    conda: 
        workflow.basedir + '/Workflow/envs/sra.yaml'
    resources:
        mem_mb = 20000,
        time = 300
    threads: 6
    params:
        dl_dir = input_dir
    log:
        log_dir + "/sra/{sra_id}_download.log"
    shell:
        """
        fasterq-dump {wildcards.sra_id} \
            --split-files \
            --threads {threads} \
            --outdir {params.dl_dir} 2> {log}
        """

## Zip SRA FastQs with parallel compression
rule parallel_gzip:
    input: 
        r1 = input_dir + "/{sra_id}_1.fastq",
        r2 = input_dir + "/{sra_id}_2.fastq"
    output:
        r1 = input_dir + "/{sra_id}_1.fastq.gz",
        r2 = input_dir + "/{sra_id}_2.fastq.gz"
    conda: 
        workflow.basedir + '/Workflow/envs/sra.yaml'
    resources:
        mem_mb = 20000,
        time = 240
    threads: 6
    log:
        log_dir + "/sra/{sra_id}_compress.log"
    shell:
        """
        pigz -p {threads} -9 {input.r1} 2> {log}
        pigz -p {threads} -9 {input.r2} 2>> {log}
        """  

