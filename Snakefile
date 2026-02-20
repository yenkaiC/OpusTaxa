configfile: "config/config.yaml"

## Load rules
include: workflow.basedir + "/Workflow/rules/initialise.smk"
include: workflow.basedir + "/Workflow/rules/sra.smk"
include: workflow.basedir + "/Workflow/rules/fastp.smk"
include: workflow.basedir + "/Workflow/rules/nohuman.smk"
include: workflow.basedir + "/Workflow/rules/metaphlan.smk"
include: workflow.basedir + "/Workflow/rules/singlem.smk"
include: workflow.basedir + "/Workflow/rules/kraken2.smk"
include: workflow.basedir + "/Workflow/rules/qc.smk"
include: workflow.basedir + "/Workflow/rules/metaspades.smk"
include: workflow.basedir + "/Workflow/rules/mlp.smk"
include: workflow.basedir + "/Workflow/rules/humann.smk"
include: workflow.basedir + "/Workflow/rules/rgi.smk"
include: workflow.basedir + "/Workflow/rules/antismash.smk"

## Define Outputs
rule all:
    input:
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
        
        ## Runs below can be conditional
        # SingleM
        expand(singlem_dir + "/{sample}_otu-table.tsv", sample=SAMPLES) if run_singlem else [],
        expand(singlem_dir + "/{sample}.spf.tsv", sample=SAMPLES) if run_singlem else [],
        # Merged table for SingleM
        singlem_dir + "/table/merged_profile.tsv" if run_singlem else [],
        directory(singlem_dir + "/table/species_by_site/") if run_singlem else [],
        
        # MetaPhlAn
        expand(metaphlan_dir + "/{sample}_profile.txt", sample=SAMPLES) if run_metaphlan else [],
        expand(metaphlan_dir + "/{sample}_bowtie.bz2", sample=SAMPLES) if run_metaphlan else [],
        # Merged table for MetaPhlAn
        metaphlan_dir + "/table/abundance_all.txt" if run_metaphlan else [],
        metaphlan_dir + "/table/abundance_species.txt" if run_metaphlan else [],

        # Kraken2
        expand(kraken2_dir + "/{sample}_report.txt", sample=SAMPLES) if run_kraken2 else [],
        expand(kraken2_dir + "/{sample}_bracken.txt", sample=SAMPLES) if run_kraken2 else [],
        # Combined Bracken table
        kraken2_dir + "/table/combined_bracken_species.txt" if run_kraken2 else [],
        
        # metaSPAdes assembly
        expand(metaspades_dir + "/{sample}/contigs.fasta", sample=SAMPLES) if run_metaspades else [],
        expand(metaspades_dir + "/{sample}/scaffolds.fasta", sample=SAMPLES) if run_metaspades else [],

        # Microbial Load Predictor (requries metaphlan)
        mlp_dir + "/load.tsv" if run_mlp and run_metaphlan else [],
        mlp_dir + "/qmp.tsv"  if run_mlp and run_metaphlan else [],

        # HUMAnN - requires MetaPhlAn (conditional)
        humann_dir + "/merged/genefamilies_cpm_unstratified.tsv" if run_humann and run_metaphlan else [],
        humann_dir + "/merged/pathabundance_cpm_unstratified.tsv" if run_humann and run_metaphlan else [],
        humann_dir + "/merged/pathcoverage_joined_unstratified.tsv" if run_humann and run_metaphlan else [],

        # RGI - Resistome analysis
        DB_dir + "/card/card.json" if run_rgi else [],
        DB_dir + "/card/wildcard/index-for-model-sequences.txt" if run_rgi else [],
        # Contig-based mode (only runs when both RGI and metaspades are enabled)
        expand(rgi_dir + "/{sample}/contigs/{sample}_rgi.txt", sample=SAMPLES) if run_rgi else [],
        expand(rgi_dir + "/{sample}/contigs/{sample}_rgi.json", sample=SAMPLES) if run_rgi else [],

        # AntiSMASH - Biosynthetic gene clusters (requires metaspades)
        expand(antismash_dir + "/{sample}/.antismash_complete", sample=SAMPLES) if run_antismash else [],        
        

## Check what one should be running
print("Config values:")
print(f"  Test files: {run_test}")
print(f"  SRA download: {download_sra}")
print(f"  MetaPhlAn: {run_metaphlan}")
print(f"  SingleM: {run_singlem}")
print(f"  Kraken2: {run_kraken2}")
print(f"  HUMAnN: {run_humann}")
print(f"  metaSPAdes: {run_metaspades}")
print(f"  MLP: {run_mlp}")
print(f"  RGI: {run_rgi}")
print(f"  AntiSMASH: {run_antismash}")