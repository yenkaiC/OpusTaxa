# Download metaphylan Database
#rule dl_metaphlan_DB:
#    output: 
#        metaphlanDB_dir + "/mpa_vJan25_CHOCOPhlAnSGB_202503.tar"
#    conda: 
#        '/Workflow/envs/metaphlan.yaml'
#    resources:
#        mem_mb=4000
#    threads: 1
#    params:
#        db_dir = metaphlanDB_dir
#    shell:
#        "metaphlan --install --index mpa_vJan25_CHOCOPhlAnSGB_202503 --db_dir {params.db_dir}"

# Run MetaPhlAn
rule metaphlan:
    input:
        r1 = nohuman_dir + "/{sample}_R1_001.fastq.gz",
        r2 = nohuman_dir + "/{sample}_R2_001.fastq.gz",
        db = metaphlanDB_dir
    output:
        profile = metaphlan_dir + "/{sample}_profile.txt",
        bowtie = metaphlan_dir + "/{sample}_bowtie.bz2"
    conda:
        workflow.basedir + "/Workflow/envs/metaphlan.yaml"
    params:
        db_dir = metaphlanDB_dir
    threads: 8
    shell:
        """
        metaphlan {input.r1},{input.r2} \
            --input_type fastq \
            --nproc {threads} \
            --index "mpa_vJan25_CHOCOPhlAnSGB_202503" \
            --db_dir {params.db_dir} \
            --mapout {output.bowtie} \
            -o {output.profile} \
            -t rel_ab_w_read_stats
        """