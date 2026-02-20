rule gutsmash_contigs:
    input:
        contigs = metaspades_dir + "/{sample}/contigs.fasta"
    output:
        index = gutsmash_dir + "/{sample}/index.html",
        complete = gutsmash_dir + "/{sample}/.gutsmash_complete"
    params:
        outdir = gutsmash_dir + "/{sample}"
    conda:
        workflow.basedir + "/Workflow/envs/gutsmash.yaml"
    threads: 8
    resources:
        mem_mb = 32000,
        runtime = 1440
    log:
        log_dir + "/gutsmash/{sample}.log"
    shell:
        """
        gutsmash \
            --taxon bacteria \
            --output-dir {params.outdir} \
            --genefinding-tool prodigal-m \
            --cpus {threads} \
            {input.contigs} 2> {log}
        
        touch {output.complete}
        """