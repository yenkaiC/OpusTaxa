rule download_fastq:
    output: 
        r1 = os.path.join(config["output"], "fastq_raw", "{sra_id}_1.fastq.gz"),
        r2 = os.path.join(config["output"], "fastq_raw", "{sra_id}_2.fastq.gz")
    params:
        dir = os.path.join(config["output"], "fastq_raw"),
        r1 = os.path.join(config["output"], "fastq_raw", "{sra_id}_1.fastq"),
        r2 = os.path.join(config["output"], "fastq_raw", "{sra_id}_2.fastq")
    threads:
        8
    conda: 
        os.path.join("..", "envs", "fasterqdump.yaml")
    shell: 
        """
        fasterq-dump -O {params.dir} {wildcards.sra_id}
        pigz -p {threads} -9 {params.r1}
        pigs -p {threads} -9 {params.r2}
        """

rule trim_fastq:
    input: 
        r1 = os.path.join(config["output"], "fastq_raw", "{sra_id}_1.fastq.gz"),
        r2 = os.path.join(config["output"], "fastq_raw", "{sra_id}_2.fastq.gz")
    output: 
        r1 = os.path.join(config["output"], "fastq_trimmed", "{sra_id}_1.fastq.gz"),
        r2 = os.path.join(config["output"], "fastq_trimmed", "{sra_id}_2.fastq.gz")
    threads:
        8
    shell: 
        """
        fastp -i {input.r1} -I {input.r2} -o {output.r1} -O {output.r2} -t {threads} ## double check this is correct
        """