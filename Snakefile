import os

configfile: os.path.join("config","config.yaml")

## Load rules
include: os.path.join(workflow.basedir, "Workflow","rules","initialise.smk")
include: os.path.join(workflow.basedir, "Workflow","rules","sra.smk")
include: os.path.join(workflow.basedir, "Workflow","rules","fastp.smk")
include: os.path.join(workflow.basedir, "Workflow","rules","nohuman.smk")
include: os.path.join(workflow.basedir, "Workflow","rules","metaphlan.smk")
include: os.path.join(workflow.basedir, "Workflow","rules","singlem.smk")
include: os.path.join(workflow.basedir, "Workflow","rules","kraken2.smk")
include: os.path.join(workflow.basedir, "Workflow","rules","qc.smk")
include: os.path.join(workflow.basedir, "Workflow","rules","metaspades.smk")
include: os.path.join(workflow.basedir, "Workflow","rules","mlp.smk")
include: os.path.join(workflow.basedir, "Workflow","rules","humann.smk")
include: os.path.join(workflow.basedir, "Workflow","rules","rgi.smk")
include: os.path.join(workflow.basedir, "Workflow","rules","antismash.smk")
include: os.path.join(workflow.basedir, "Workflow","rules","strainphlan.smk")


## Define Outputs
rule all:
    input:
        # Data processing and QC
        expand(os.path.join(clean_dir, "{sample}_R1_001.fastq.gz"), sample=SAMPLES),
        expand(os.path.join(clean_dir, "{sample}_R2_001.fastq.gz"), sample=SAMPLES),
        expand(os.path.join(nohuman_dir, "{sample}_R1_001.fastq.gz"), sample=SAMPLES),
        expand(os.path.join(nohuman_dir, "{sample}_R2_001.fastq.gz"), sample=SAMPLES),
        expand(os.path.join(raw_qc_dir, "{sample}_R1_001_fastqc.html"), sample=SAMPLES),
        expand(os.path.join(raw_qc_dir, "{sample}_R2_001_fastqc.html"), sample=SAMPLES),
        expand(os.path.join(fastp_qc_dir, "{sample}_R1_001_fastqc.html"), sample=SAMPLES),
        expand(os.path.join(fastp_qc_dir, "{sample}_R2_001_fastqc.html"), sample=SAMPLES),
        
        # MultiQC reports
        os.path.join(multiqc_dir, "raw_multiqc_report.html"),
        os.path.join(multiqc_dir, "fastp_multiqc_report.html"),
        os.path.join(multiqc_dir, "nohuman_multiqc_report.html"),
        
        ## Runs below can be conditional
        # SingleM
        expand(os.path.join(singlem_dir, "{sample}_otu-table.tsv"), sample=SAMPLES) if run_singlem else [],
        expand(os.path.join(singlem_dir, "{sample}.spf.tsv"), sample=SAMPLES) if run_singlem else [],
        # Merged table for SingleM
        os.path.join(singlem_dir, "table","merged_profile.tsv") if run_singlem else [],
        directory(os.path.join(singlem_dir, "table","species_by_site")) if run_singlem else [],
        os.path.join(singlem_dir, "table","merged_prokaryotic_fraction.tsv") if run_singlem else [],
        
        # MetaPhlAn
        expand(os.path.join(metaphlan_dir, "{sample}_profile.txt"), sample=SAMPLES) if run_metaphlan else [],
        expand(os.path.join(metaphlan_dir, "{sample}_bowtie.bz2"), sample=SAMPLES) if run_metaphlan else [],
        # Merged table for MetaPhlAn
        os.path.join(metaphlan_dir, "table","abundance_all.txt") if run_metaphlan else [],
        os.path.join(metaphlan_dir, "table","abundance_species.txt") if run_metaphlan else [],

        expand(os.path.join(strainphlan_dir, "output","{species}","RAxML_bestTree.{species}.StrainPhlAn4.tre"),
        species=STRAINPHLAN_SPECIES) if run_strainphlan and STRAINPHLAN_SPECIES else [],

        # Kraken2
        expand(os.path.join(kraken2_dir, "{sample}_report.txt"), sample=SAMPLES) if run_kraken2 else [],
        expand(os.path.join(kraken2_dir, "{sample}_bracken.txt"), sample=SAMPLES) if run_kraken2 else [],
        # Combined Bracken table
        os.path.join(kraken2_dir, "table","combined_bracken_species.txt") if run_kraken2 else [],
        
        # metaSPAdes assembly
        expand(os.path.join(metaspades_dir, "{sample}","contigs.fasta"), sample=SAMPLES) if run_metaspades else [],
        oexpand(os.path.join(metaspades_dir, "{sample}","scaffolds.fasta"), sample=SAMPLES) if run_metaspades else [],

        # Microbial Load Predictor (requries metaphlan)
        os.path.join(mlp_dir, ".mlp_package_installed") if run_mlp else [],
        os.path.join(mlp_dir, "load.tsv") if run_mlp else [],
        os.path.join(mlp_dir, "qmp.tsv")  if run_mlp else [],

        # HUMAnN - requires MetaPhlAn (conditional)
        os.path.join(humann_dir, "merged","genefamilies_cpm_unstratified.tsv") if run_humann else [],
        os.path.join(humann_dir, "merged","pathabundance_cpm_unstratified.tsv") if run_humann else [],
        os.path.join(humann_dir, "merged","pathcoverage_joined_unstratified.tsv") if run_humann else [],

        # RGI - Resistome analysis
        os.path.join(DB_dir, "card",".download_complete") if run_rgi else [],
        expand(os.path.join(rgi_dir, "{sample}","contigs","{sample}_rgi.txt"), sample=SAMPLES) if run_rgi else [],
        expand(os.path.join(rgi_dir, "{sample}","contigs","{sample}_rgi.json"), sample=SAMPLES) if run_rgi else [],
        os.path.join(rgi_dir, "table","rgi_merged.tsv") if run_rgi else [],

        # AntiSMASH - Biosynthetic gene clusters (requires metaspades)
        expand(os.path.join(antismash_dir, "{sample}",".antismash_complete"), sample=SAMPLES) if run_antismash else [],
        os.path.join(antismash_dir, "table","antismash_summary.tsv") if run_antismash else [],
        

## Check what one should be running
print("Config values:")
print(f"  Test files: {run_test}")
print(f"  SRA download: {download_sra}")
print(f"  MetaPhlAn: {run_metaphlan}")
print(f"  StrainPhlAn: {run_strainphlan}")
print(f"  SingleM: {run_singlem}")
print(f"  Kraken2: {run_kraken2}")
print(f"  HUMAnN: {run_humann}")
print(f"  metaSPAdes: {run_metaspades}")
print(f"  MLP: {run_mlp}")
print(f"  RGI: {run_rgi}")
print(f"  AntiSMASH: {run_antismash}")