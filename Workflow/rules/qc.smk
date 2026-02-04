# Declare FastQC inputs, outputs and shellscript for Raw data
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
    threads: 4
    resources:
        mem_mb = 4000,
        time = 80
    shell:
        "fastqc --outdir {params} {input}"

# Declare FastQC inputs, outputs and shellscript for FastP outputs
rule fastp_qc:
    input:
        input_dir + "/{sample}_{read}_001.fastq.gz"
    output:
        fastp_qc_dir + "/{sample}_{read}_001_fastqc.html",
        fastp_qc_dir + "/{sample}_{read}_001_fastqc.zip"
    params:
        fastp_qc_dir
    conda: 
        '../envs/fastqc.yaml'
    threads: 4
    resources:
        mem_mb = 4000,
        time = 80
    shell:
        "fastqc --outdir {params} {input}"

# Declare FastQC inputs, outputs and shellscript for FastP outputs
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
    threads: 4
    resources:
        mem_mb = 4000,
        time = 80
    shell:
        "fastqc --outdir {params} {input}"

# MultiQC
rule multi_qc:
    input:
        raw_fastqc = expand(raw_qc_dir + "/{sample}_{read}_001_fastqc.zip", 
                           sample=SAMPLES, read=["R1", "R2"]),
        fastp_fastqc = expand(fastp_qc_dir + "/{sample}_{read}_001_fastqc.zip", 
                             sample=SAMPLES, read=["R1", "R2"]),
        nohuman_fastqc = expand(nohuman_qc_dir + "/{sample}_{read}_001_fastqc.zip", 
                             sample=SAMPLES, read=["R1", "R2"])
    output: 
        multiqc_dir + "/raw_multiqc_report.html",
        multiqc_dir + "/fastp_multiqc_report.html",
        multiqc_dir + "/nohuman_multiqc_report.html"
    params:
        multiqc_dir
    conda:
        '../envs/multiqc.yaml'
    threads: 4
    resources:
        mem_mb = 4000,
        time = 80
    shell:
        """
        multiqc {raw_qc_dir} -o {params} -n raw_multiqc_report.html
        multiqc {fastp_qc_dir} -o {params} -n fastp_multiqc_report.html
        multiqc {nohuman_qc_dir} -o {params} -n nohuman_multiqc_report.html
        """