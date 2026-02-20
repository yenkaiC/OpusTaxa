rule antismash_contigs:
    input:
        contigs = metaspades_dir + "/{sample}/contigs.fasta"
    output:
        index = antismash_dir + "/{sample}/index.html",
        complete = antismash_dir + "/{sample}/.antismash_complete"
    params:
        outdir = antismash_dir + "/{sample}"
    conda:
        workflow.basedir + "/Workflow/envs/antismash.yaml"
    threads: 8
    resources:
        mem_mb = 32000,
        runtime = 1440  # 24 hours
    log:
        log_dir + "/antismash/{sample}.log"
    shell:
        """
        antismash \
            --taxon bacteria \
            --output-dir {params.outdir} \
            --genefinding-tool prodigal-m \
            --cpus {threads} \
            --minimal \
            --skip-zip-file \
            {input.contigs} 2> {log}
        
        touch {output.complete}
        """