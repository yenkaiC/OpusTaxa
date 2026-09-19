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
        mem_mb = 200000,  # 200GB
        runtime = 1439       # 24 hours
    log:
        log_dir + "/metaspades/{sample}.log"
    shell:
        """
        set -euo pipefail

        mkdir -p {params.outdir} $(dirname {log})

        spades.py --meta \
            -1 {input.r1} \
            -2 {input.r2} \
            -t {threads} \
            -m {params.mem_gb} \
            -o {params.outdir} 2> {log}

        # Preserve the SPAdes internal log before cleanup
        if [ -f "{params.outdir}/spades.log" ]; then
            cp "{params.outdir}/spades.log" "$(dirname {log})/{wildcards.sample}_spades.log"
        fi

        # Cleanup scoped explicitly to {params.outdir} via find (no `cd`),
        # so a failed path can never delete files in the working directory
        find {params.outdir} -mindepth 1 -maxdepth 1 \
            ! -name 'contigs.fasta' \
            ! -name 'scaffolds.fasta' \
            -exec rm -rf {{}} +
        """