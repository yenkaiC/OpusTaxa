configfile: "config/config.yaml"

## Load rules
include: workflow.basedir + "/Workflow/rules/initialise.smk"
include: workflow.basedir + "/Workflow/rules/sra.smk"
include: workflow.basedir + "/Workflow/rules/fastp.smk"
include: workflow.basedir + "/Workflow/rules/nohuman.smk"
include: workflow.basedir + "/Workflow/rules/metaphlan.smk"
include: workflow.basedir + "/Workflow/rules/singlem.smk"
include: workflow.basedir + "/Workflow/rules/qc.smk"

## Define Outputs
rule all:
    input:
        # SRA downloads - conditional
        expand(input_dir + "/{sra_id}_1.fastq.gz", sra_id=SRA_IDS) if download_sra and SRA_IDS else [],
        expand(input_dir + "/{sra_id}_2.fastq.gz", sra_id=SRA_IDS) if download_sra and SRA_IDS else [],
        
        # Data processing and QC
        expand(clean_dir + "/{sample}_R1_001.fastq.gz", sample=SAMPLES),
        expand(clean_dir + "/{sample}_R2_001.fastq.gz", sample=SAMPLES),
        expand(nohuman_dir + "/{sample}_R1_001.fastq.gz", sample=SAMPLES),
        expand(nohuman_dir + "/{sample}_R2_001.fastq.gz", sample=SAMPLES),
        expand(raw_qc_dir + "/{sample}_R1_001_fastqc.html", sample=SAMPLES),
        expand(raw_qc_dir + "/{sample}_R2_001_fastqc.html", sample=SAMPLES),
        expand(fastp_qc_dir + "/{sample}_R1_001_fastqc.html", sample=SAMPLES),
        expand(fastp_qc_dir + "/{sample}_R2_001_fastqc.html", sample=SAMPLES),
        
        # MultiQC reports
        multiqc_dir + "/raw_multiqc_report.html",
        multiqc_dir + "/fastp_multiqc_report.html",
        multiqc_dir + "/nohuman_multiqc_report.html",
        
        # Conditional SingleM
        expand(singlem_dir + "/{sample}_otu-table.tsv", sample=SAMPLES) if run_singlem else [],
        expand(singlem_dir + "/{sample}.spf.tsv", sample=SAMPLES) if run_singlem else [],
        # Conditional MetaPhlAn
        expand(metaphlan_dir + "/{sample}_profile.txt", sample=SAMPLES) if run_metaphlan else [],
        expand(metaphlan_dir + "/{sample}_bowtie.bz2", sample=SAMPLES) if run_metaphlan else [],
        # Merged table for MetaPhlAn
        metaphlan_dir + "/table/abundance_all.txt" if config.get("metaphlan", True) else [],
        metaphlan_dir + "/table/abundance_species.txt" if config.get("metaphlan", True) else []
        

print("Config values:")
print(f"  metaphlan: {run_metaphlan}")
print(f"  singlem: {run_singlem}")
print(f"  SRA download: {download_sra}")
