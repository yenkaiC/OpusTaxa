## Download Kraken2 PlusPF-16 Database (16GB)
rule dl_kraken2_DB:
    output:
        checkpoint = kraken2DB_dir + "/.download_complete"
    conda:
        workflow.basedir + '/Workflow/envs/kraken2.yaml'
    params:
        db_dir = kraken2DB_dir
    resources:
        mem_mb = 8000,
        time = 480
    threads: 4
    log:
        log_dir + "/kraken2/database_dl.log"
    shell:
        """
        if [ ! -f "{params.db_dir}/hash.k2d" ]; then
            mkdir -p {params.db_dir}
            # Includes: archaea, bacteria, viral, plasmid, human, UniVec_Core, protozoa, fungi
            wget -P {params.db_dir} https://genome-idx.s3.amazonaws.com/kraken/k2_pluspf_16_GB_20251015.tar.gz 2> {log}
            tar -xzvf {params.db_dir}/k2_pluspf_16gb_20240112.tar.gz -C {params.db_dir} 2>> {log}
            rm {params.db_dir}/k2_pluspf_16gb_20240112.tar.gz
        else
            echo "Kraken2 PlusPF-16 database already exists, skipping download" > {log}
        fi
        touch {output.checkpoint}
        """
# Choose your own database at https://benlangmead.github.io/aws-indexes/k2

## Run Kraken2 on paired-end reads
rule kraken2:
    input:
        r1 = nohuman_dir + "/{sample}_R1_001.fastq.gz",
        r2 = nohuman_dir + "/{sample}_R2_001.fastq.gz",
        db = kraken2DB_dir + "/.download_complete"
    output:
        report = kraken2_dir + "/{sample}_report.txt",
        output = kraken2_dir + "/{sample}_output.txt"
    conda:
        workflow.basedir + "/Workflow/envs/kraken2.yaml"
    params:
        db_dir = kraken2DB_dir
    threads: 8
    resources:
        mem_mb = 64000,
        time = 480
    log:
        log_dir + "/kraken2/{sample}.log"
    shell:
        """
        kraken2 \
            --db {params.db_dir} \
            --threads {threads} \
            --paired {input.r1} {input.r2} \
            --report {output.report} \
            --output {output.output} \
            --gzip-compressed 2> {log}
        """

## Run Bracken for abundance estimation (optional but recommended)
rule bracken:
    input:
        report = kraken2_dir + "/{sample}_report.txt",
        db = kraken2DB_dir + "/.download_complete"
    output:
        bracken_out = kraken2_dir + "/{sample}_bracken.txt",
        bracken_report = kraken2_dir + "/{sample}_bracken_report.txt"
    conda:
        workflow.basedir + "/Workflow/envs/kraken2.yaml"
    params:
        db_dir = kraken2DB_dir,
        read_len = 150,  # Adjust based on your sequencing read length
        level = "S"      # S=species, G=genus, F=family, etc.
    threads: 1
    resources:
        mem_mb = 8000,
        time = 60
    log:
        log_dir + "/kraken2/{sample}_bracken.log"
    shell:
        """
        bracken \
            -d {params.db_dir} \
            -i {input.report} \
            -o {output.bracken_out} \
            -w {output.bracken_report} \
            -r {params.read_len} \
            -l {params.level} 2> {log}
        """

## Combine Bracken reports across samples
rule combine_bracken_reports:
    input:
        expand(kraken2_dir + "/{sample}_bracken.txt", sample=SAMPLES)
    output:
        combined = kraken2_dir + "/table/combined_bracken_species.txt"
    conda:
        workflow.basedir + "/Workflow/envs/kraken2.yaml"
    log:
        log_dir + "/kraken2/combine_reports.log"
    shell:
        """
        mkdir -p {kraken2_dir}/table
        combine_bracken_outputs.py \
            --files {input} \
            -o {output.combined} 2> {log}
        """
