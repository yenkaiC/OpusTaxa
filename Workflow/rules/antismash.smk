## AntiSMASH - Biosynthetic Gene Cluster detection
## Contig-based annotation (requires metaSPAdes)

## Download AntiSMASH databases

rule antismash_download_databases:
    output:
        checkpoint = DB_dir + "/antismash/.databases_downloaded"
    log:
        log_dir + "/antismash/download_databases.log"
    conda:
        "../envs/antismash.yaml"
    params:
        db_dir = DB_dir + "/antismash"
    resources:
        mem_mb = 8000,
        runtime = 480
    threads: 1
    shell:
        """
        mkdir -p {params.db_dir}
        if [ ! -f "{params.db_dir}/clusterblast/proteins.dmnd" ]; then
            download-antismash-databases --database-dir {params.db_dir} 2> {log}
        else
            echo "AntiSMASH databases already exist, skipping download" > {log}
        fi
        touch {output.checkpoint}
        """

rule antismash_contigs:
    input:
        fasta = metaspades_dir + "/{sample}/contigs.fasta",
        db = DB_dir + "/antismash/.databases_downloaded"
    output:
        html = antismash_dir + "/{sample}/index.html",
        gbk = antismash_dir + "/{sample}/contigs.gbk",
        json = antismash_dir + "/{sample}/contigs.json",
        complete = touch(antismash_dir + "/{sample}/.antismash_complete")
    log:
        log_dir + "/antismash/{sample}.log"
    conda:
        "../envs/antismash.yaml"
    params:
        db_dir = DB_dir + "/antismash",
        out_dir = antismash_dir + "/{sample}"
    threads: 8
    resources:
        mem_mb = 16000,
        runtime = 960
    shell:
        """
        # Remove partial output from previous failed runs
        if [ -d "{params.out_dir}" ]; then
            rm -rf {params.out_dir}
        fi
        
        antismash \
            --taxon bacteria \
            --output-dir {params.out_dir} \
            --databases {params.db_dir} \
            --genefinding-tool prodigal-m \
            --cpus {threads} \
            {input.fasta} 2> {log}
        """