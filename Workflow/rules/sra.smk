## SRA IDs come from initialise.smk (validated there)

## Download FastQ File from SRA
rule SRA_downloader:
    output:
        r1 = temp(input_dir + "/{sra_id}_1.fastq"),  # temp() marks for auto-deletion after compression
        r2 = temp(input_dir + "/{sra_id}_2.fastq")
    conda: 
        workflow.basedir + '/Workflow/envs/sra.yaml'
    container:
        get_container("sra")
    group: "sra_download"
    resources:
        get_mem("SRA_downloader"),
        runtime = 500
    threads: 10
    params:
        dl_dir = input_dir
    log:
        log_dir + "/sra/{sra_id}_download.log"
    shell:
        """
        status=0
        fasterq-dump {wildcards.sra_id} \
            --split-files \
            --threads {threads} \
            --outdir {params.dl_dir} > {log} 2>&1 || status=$?

        # Record and skip accessions that cannot be downloaded, or that yield no
        # _1/_2 pair (barcoded runs write e.g. a lone _4.fastq). Later runs then
        # drop them at startup instead of failing here again.
        if [ ! -f "{output.r1}" ] || [ ! -f "{output.r2}" ]; then
            produced=$(ls {params.dl_dir}/{wildcards.sra_id}*.fastq 2>/dev/null | tr '\n' ' ' || true)
            if [ "$status" -ne 0 ]; then
                reason="missing"; detail="fasterq-dump failed (exit $status)"
            else
                reason="single"; detail="no paired _1/_2 output (got: ${{produced:-none}})"
            fi
            echo "ERROR: {wildcards.sra_id}: $detail" >> {log}
            mkdir -p logs/sra
            printf '%s\t%s\t%s\n' "{wildcards.sra_id}" "$reason" "$detail" >> logs/sra/sra_validation.tsv
            rm -f {params.dl_dir}/{wildcards.sra_id}*.fastq
            exit 1
        fi
        """

## Zip SRA FastQs with parallel compression
rule parallel_gzip:
    input: 
        r1 = input_dir + "/{sra_id}_1.fastq",
        r2 = input_dir + "/{sra_id}_2.fastq"
    output:
        r1 = input_dir + "/{sra_id}_1.fastq.gz",
        r2 = input_dir + "/{sra_id}_2.fastq.gz"
    conda: 
        workflow.basedir + '/Workflow/envs/sra.yaml'
    container:
        get_container("sra")
    group: "sra_download"
    resources:
        get_mem("parallel_gzip"),
        runtime = 240
    threads: 10
    log:
        log_dir + "/sra/{sra_id}_compress.log"
    shell:
        """
        pigz -p {threads} -9 {input.r1} 2> {log}
        pigz -p {threads} -9 {input.r2} 2>> {log}
        """  

