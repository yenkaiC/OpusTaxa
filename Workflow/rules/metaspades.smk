## Run metaSPAdes for metagenome assembly
rule metaspades:
    input:
        r1 = nohuman_dir + "/{sample}_R1_001.fastq.gz",
        r2 = nohuman_dir + "/{sample}_R2_001.fastq.gz"
    output:
        contigs = metaspades_dir + "/{sample}/contigs.fasta",       # For RGI
        scaffolds = metaspades_dir + "/{sample}/scaffolds.fasta",   # For Daedalus
    conda:
        workflow.basedir + "/Workflow/envs/spades.yaml"
    container:
        get_container("metaspades")
    params:
        outdir = metaspades_dir + "/{sample}",
        mem_gb = lambda wildcards, resources: int(resources.mem_mb / 1000)
    threads: get_threads("metaspades")
    resources:
        mem_mb = 100000,  # 100GB
        runtime = 2880       # 48 hours
    log:
        log_dir + "/metaspades/{sample}.log"
    shell:
        "spades.py --meta "
            "-1 {input.r1} "
            "-2 {input.r2} "
            "-t {threads} "
            "-m {params.mem_gb} "
            "-o {params.outdir} 2> {log}; "
        "cd {params.outdir}; "
        r"ls | grep -v -E '^(contigs\.fasta|scaffolds\.fasta)$' | xargs rm -rf; "
