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

## Filter contigs below minimum length threshold before AntiSMASH
# BGC detection requires sufficient sequence context; short contigs add noise and runtime
# Default threshold: 1000bp — adjust min_contig_len in config if needed
rule filter_contigs:
    input:
        fasta = metaspades_dir + "/{sample}/contigs.fasta"
    output:
        filtered = metaspades_dir + "/{sample}/contigs_filtered.fasta"
    params:
        min_len = config.get("min_contig_len", 1000)
    threads: 8
    resources:
        mem_mb = 24000,
        runtime = 240
    log:
        log_dir + "/antismash/{sample}_filter.log"
    shell:
        """
        mkdir -p $(dirname {output.filtered})
        awk 'BEGIN {{seq=""; header=""}}
             /^>/ {{
                 if (header != "" && length(seq) >= {params.min_len})
                     print header "\\n" seq;
                 header=$0; seq=""
             }}
             !/^>/ {{seq=seq $0}}
             END {{
                 if (header != "" && length(seq) >= {params.min_len})
                     print header "\\n" seq
             }}' {input.fasta} > {output.filtered} 2> {log}

        total=$(grep -c "^>" {input.fasta} || true)
        kept=$(grep -c "^>" {output.filtered} || true)
        echo "Filtered contigs: ${{kept}}/${{total}} kept (>= {params.min_len} bp)" >> {log}
        """

rule antismash_contigs:
    input:
        fasta = metaspades_dir + "/{sample}/contigs_filtered.fasta",
        db = "Database/antismash/.databases_downloaded"
    output:
        html = antismash_dir + "/{sample}/index.html",
        gbk = antismash_dir + "/{sample}/contigs_filtered.gbk",
        json = antismash_dir + "/{sample}/contigs_filtered.json",
        complete = touch(antismash_dir + "/{sample}/.antismash_complete")
    log:
        log_dir + "/antismash/{sample}.log"
    conda:
        "../envs/antismash.yaml"
    params:
        db_dir = DB_dir + "/antismash",
        out_dir = antismash_dir + "/{sample}"
    threads: 16
    resources:
        mem_mb = 32000,
        runtime = 2880
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

## Generate a merged summary table from all antiSMASH outputs
rule antismash_summary_table:
    input:
        complete = expand(antismash_dir + "/{sample}/.antismash_complete", sample=SAMPLES)
    output:
        summary = antismash_dir + "/table/antismash_summary.tsv"
    params:
        antismash_dir = antismash_dir,
        samples = SAMPLES
    log:
        log_dir + "/antismash/summary_table.log"
    resources:
        mem_mb = 4000,
        runtime = 30
    threads: 1
    script:
        workflow.basedir + "/Workflow/scripts/antismash_summary.py"