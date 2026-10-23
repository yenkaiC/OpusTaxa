## Declare FastQC inputs, outputs and shellscript for Raw data
rule raw_qc:
    input:
        input_dir + "/{sample}_{read}_001.fastq.gz"
    output:
        raw_qc_dir + "/{sample}_{read}_001_fastqc.html",
        raw_qc_dir + "/{sample}_{read}_001_fastqc.zip"
    params:
        raw_qc_dir
    conda: 
        '../envs/fastqc.yaml'
    container:
        get_container("fastqc")
    threads: get_threads("fastqc")
    resources:
        mem_mb = get_mem("raw_qc"),
        runtime = 80
    priority: 50
    log: 
        log_dir + "/fastqc/raw/{sample}_{read}.log"
    shell:
        """
        mkdir -p $(dirname {log})
        fastqc --outdir {params} {input} > {log} 2>&1
        """

## Declare FastQC inputs, outputs and shellscript for FastP outputs
rule fastp_qc:
    input:
        clean_dir + "/{sample}_{read}_001.fastq.gz"
    output:
        fastp_qc_dir + "/{sample}_{read}_001_fastqc.html",
        fastp_qc_dir + "/{sample}_{read}_001_fastqc.zip"
    params:
        fastp_qc_dir
    conda: 
        '../envs/fastqc.yaml'
    container:
        get_container("fastqc")
    threads: get_threads("fastqc")
    resources:
        mem_mb = get_mem("fastp_qc"),
        runtime = 60
    priority: 50
    log: 
        log_dir + "/fastqc/fastp/{sample}_{read}.log"
    shell:
        """
        mkdir -p $(dirname {log})
        fastqc --outdir {params} {input} > {log} 2>&1
        """

## Declare FastQC inputs, outputs and shellscript for NoHuman outputs
rule nohuman_qc:
    input:
        nohuman_dir + "/{sample}_{read}_001.fastq.gz"
    output:
        nohuman_qc_dir + "/{sample}_{read}_001_fastqc.html",
        nohuman_qc_dir + "/{sample}_{read}_001_fastqc.zip"
    params:
        nohuman_qc_dir
    conda: 
        '../envs/fastqc.yaml'
    container:
        get_container("fastqc")
    threads: get_threads("fastqc")
    priority: 50
    log:
        log_dir + "/fastqc/nohuman/{sample}_{read}.log"
    resources:
        mem_mb = get_mem("nohuman_qc"),
        runtime = 80
    shell:
        """
        mkdir -p $(dirname {log})
        fastqc --outdir {params} {input} > {log} 2>&1
        """

## MultiQC
# Takes in FastQC results from the raw, fastp, and nohuman data and summarises QC results
rule multi_qc:
    input:
        raw_fastqc = expand(raw_qc_dir + "/{sample}_{read}_001_fastqc.zip", 
                           sample=SAMPLES, read=["R1", "R2"]),
        fastp_fastqc = expand(fastp_qc_dir + "/{sample}_{read}_001_fastqc.zip", 
                             sample=SAMPLES, read=["R1", "R2"]),
        nohuman_fastqc = expand(nohuman_qc_dir + "/{sample}_{read}_001_fastqc.zip", 
                             sample=SAMPLES, read=["R1", "R2"]) if run_nohuman else []
    output: 
        multiqc_dir + "/raw_multiqc_report.html",
        multiqc_dir + "/fastp_multiqc_report.html",
        multiqc_dir + "/nohuman_multiqc_report.html" if run_nohuman else []
    priority: 45
    params:
        outdir = multiqc_dir,
        run_nohuman = run_nohuman
    conda:
        '../envs/multiqc.yaml'
    container:
        get_container("multiqc")
    threads: 4
    log:
        log_dir + "/multiqc/multiqc.log"
    resources:
        mem_mb = get_mem("multi_qc"),
        runtime = 80
    shell:
        """
        mkdir -p $(dirname {log})
        multiqc {raw_qc_dir} -o {params.outdir} -n raw_multiqc_report.html --force > {log} 2>&1
        multiqc {fastp_qc_dir} -o {params.outdir} -n fastp_multiqc_report.html --force >> {log} 2>&1
        if [ "{params.run_nohuman}" = "True" ]; then
            multiqc {nohuman_qc_dir} -o {params.outdir} -n nohuman_multiqc_report.html --force >> {log} 2>&1
        fi
        """