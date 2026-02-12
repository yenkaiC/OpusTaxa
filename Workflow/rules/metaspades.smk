## Run metaSPAdes for metagenome assembly
rule metaspades:
    input:
        r1 = nohuman_dir + "/{sample}_R1_001.fastq.gz",
        r2 = nohuman_dir + "/{sample}_R2_001.fastq.gz"
    output:
        scaffolds = metaspades_dir + "/{sample}/scaffolds.fasta",
    conda:
        workflow.basedir + "/Workflow/envs/spades.yaml"
    params:
        outdir = metaspades_dir + "/{sample}"
    threads: 10
    resources:
        mem_mb = 80000,  # 80GB
        time = 2880       # 48 hours
    log:
        log_dir + "/metaspades/{sample}.log"
    shell:
        """
        spades.py --meta \
            -1 {input.r1} \
            -2 {input.r2} \
            -t {threads} \
            -m 80 \
            -o {params.outdir} 2> {log}
        
        # Keep only essential outputs, remove everything else
        find {params.outdir} -maxdepth 1 \
            ! -name 'scaffolds.fasta' \
            ! -name '.' \
            -exec rm -rf {{}} +
        """