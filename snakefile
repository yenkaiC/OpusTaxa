import pandas as pd

configfile: "config/config.yaml"

# Read samples from CSV
#samples_df = pd.read_csv("samples.csv")
#SAMPLES = samples_df['sample'].tolist()
#SAMPLES = samples_df['sample'].str.replace(r'_R[12]_001$', '', regex=True).unique().tolist()

include: workflow.basedir + "/workflow/rules/initialise.smk"
include: workflow.basedir + "/workflow/rules/fastp.smk"
include: workflow.basedir + "/workflow/rules/nohuman.smk"
include: workflow.basedir + "/workflow/rules/metaphlan.smk"
include: workflow.basedir + "/workflow/rules/singlem.smk"
include: workflow.basedir + "/workflow/rules/qc.smk"

# Define Outputs
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
        #expand(singlem_dir + "/{sample}_otu-table.tsv", sample=SAMPLES),
        #expand(metaphlan_dir + "/{sample}_profile.txt", sample=SAMPLES),
        #expand(metaphlan_dir + "/{sample}_bowtie.bz2", sample=SAMPLES)

