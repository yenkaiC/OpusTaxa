configfile: "config/config.yaml"

## Load rules
include: workflow.basedir + "/Workflow/rules/initialise.smk"
include: workflow.basedir + "/Workflow/rules/fastp.smk"
include: workflow.basedir + "/Workflow/rules/nohuman.smk"
include: workflow.basedir + "/Workflow/rules/metaphlan.smk"
include: workflow.basedir + "/Workflow/rules/singlem.smk"
include: workflow.basedir + "/Workflow/rules/qc.smk"

## Define Outputs
rule all:
    input:
        expand(clean_dir + "/{sample}_R1_001.fastq.gz", sample=SAMPLES),
        expand(clean_dir + "/{sample}_R2_001.fastq.gz", sample=SAMPLES),
        expand(nohuman_dir + "/{sample}_R1_001.fastq.gz", sample=SAMPLES),
        expand(nohuman_dir + "/{sample}_R2_001.fastq.gz", sample=SAMPLES),
        expand(raw_qc_dir + "/{sample}_R1_001_fastqc.html", sample=SAMPLES),
        expand(raw_qc_dir + "/{sample}_R2_001_fastqc.html", sample=SAMPLES),
        expand(fastp_qc_dir + "/{sample}_R1_001_fastqc.html", sample=SAMPLES),
        expand(fastp_qc_dir + "/{sample}_R2_001_fastqc.html", sample=SAMPLES),
        expand(nohuman_qc_dir + "/{sample}_R1_001_fastqc.html", sample=SAMPLES),
        expand(nohuman_qc_dir + "/{sample}_R2_001_fastqc.html", sample=SAMPLES),
        multiqc_dir + "/raw_multiqc_report.html",
        multiqc_dir + "/fastp_multiqc_report.html",
        multiqc_dir + "/nohuman_multiqc_report.html",
        expand(singlem_dir + "/{sample}_otu-table.tsv", sample=SAMPLES),
        expand(singlem_dir + "/{sample}.spf.tsv", sample=SAMPLES),
        expand(metaphlan_dir + "/{sample}_profile.txt", sample=SAMPLES),
        expand(metaphlan_dir + "/{sample}_bowtie.bz2", sample=SAMPLES)