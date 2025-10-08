rule run_Kraken2:
    input:
        r1 = os.path.join(config["output"], "fastq_trimmed", "{sra_id}_1.fastq.gz"),
        r2 = os.path.join(config["output"], "fastq_trimmed", "{sra_id}_2.fastq.gz")
    output: 
        k1 = os.path.join(config["output"], "{sra_id}_kraken_ouput", "kraken_taxonomy.txt")
        k2 = os.path.join(config["output"], "{sra_id}_kraken_ouput", "kraken_output.txt")
    params:
        DB_Loc = os.path.join(config["output"], "fastq_raw"),
        r1 = os.path.join(config["output"], "fastq_raw", "{sra_id}_1.fastq"),
        r2 = os.path.join(config["output"], "fastq_raw", "{sra_id}_2.fastq")
    threads:
        8
    conda: 
        os.path.join("..", "envs", "krack.yaml")
    shell: 
        """
        kraken2 \
            --db {DB_Loc} \ 
            --paired \
            --threads {threads} \
            --report {k1} \
            --output {k2} \
            {r1} {r2}
        """

rule extract_human: