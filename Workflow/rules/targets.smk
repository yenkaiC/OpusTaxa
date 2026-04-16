
# create dict for pipeline target files
targets = dict()

# Data processing and QC
targets["qc"] = [
    expand(os.path.join(clean_dir, "{sample}_R1_001.fastq.gz"), sample=SAMPLES),
    expand(os.path.join(clean_dir, "{sample}_R2_001.fastq.gz"), sample=SAMPLES),
    expand(os.path.join(nohuman_dir, "{sample}_R1_001.fastq.gz"), sample=SAMPLES),
    expand(os.path.join(nohuman_dir, "{sample}_R2_001.fastq.gz"), sample=SAMPLES),
    expand(os.path.join(raw_qc_dir, "{sample}_R1_001_fastqc.html"), sample=SAMPLES),
    expand(os.path.join(raw_qc_dir, "{sample}_R2_001_fastqc.html"), sample=SAMPLES),
    expand(os.path.join(fastp_qc_dir, "{sample}_R1_001_fastqc.html"), sample=SAMPLES),
    expand(os.path.join(fastp_qc_dir, "{sample}_R2_001_fastqc.html"), sample=SAMPLES),
    os.path.join(multiqc_dir, "raw_multiqc_report.html"),
    os.path.join(multiqc_dir, "fastp_multiqc_report.html"),
    os.path.join(multiqc_dir, "nohuman_multiqc_report.html"),
]

# SingleM
targets["singlem"] = [
    expand(os.path.join(singlem_dir, "{sample}_otu-table.tsv"), sample=SAMPLES),
    expand(os.path.join(singlem_dir, "{sample}.spf.tsv"), sample=SAMPLES),
    os.path.join(singlem_dir, "table","merged_profile.tsv"),
    directory(os.path.join(singlem_dir, "table","species_by_site")),
    os.path.join(singlem_dir, "table","merged_prokaryotic_fraction.tsv"),
]

# MetaPhlAn
targets["metaphlan"] = [
    expand(os.path.join(metaphlan_dir, "{sample}_profile.txt"), sample=SAMPLES),
    expand(os.path.join(metaphlan_dir, "{sample}_bowtie.bz2"), sample=SAMPLES),
    os.path.join(metaphlan_dir, "table","abundance_all.txt"),
    os.path.join(metaphlan_dir, "table","abundance_species.txt"),
]

# strainphlan
targets["strainphlan"] = [
    expand(os.path.join(strainphlan_dir, "output","{species}","RAxML_bestTree.{species}.StrainPhlAn4.tre"),
        species=STRAINPHLAN_SPECIES),
]

# Kraken2
targets["kraken2"] = [
    expand(os.path.join(kraken2_dir, "{sample}_report.txt"), sample=SAMPLES),
    expand(os.path.join(kraken2_dir, "{sample}_bracken.txt"), sample=SAMPLES),
    os.path.join(kraken2_dir, "table","combined_bracken_species.txt"),
]

# metaSPAdes assembly
targets["metaspades"] = [
    expand(os.path.join(metaspades_dir, "{sample}","contigs.fasta"), sample=SAMPLES),
    expand(os.path.join(metaspades_dir, "{sample}","scaffolds.fasta"), sample=SAMPLES),
]

# Microbial Load Predictor (requries metaphlan)
targets["mlp"] = [
    os.path.join(mlp_dir, ".mlp_package_installed"),
    os.path.join(mlp_dir, "load.tsv"),
    os.path.join(mlp_dir, "qmp.tsv"),
]

# HUMAnN - requires MetaPhlAn (conditional)
targets["human"] = [
    os.path.join(humann_dir, "merged","genefamilies_cpm_unstratified.tsv"),
    os.path.join(humann_dir, "merged","pathabundance_cpm_unstratified.tsv"),
    os.path.join(humann_dir, "merged","pathcoverage_joined_unstratified.tsv"),
]

# RGI - Resistome analysis
targets["rgi"] = [
    os.path.join(DB_dir, "card",".download_complete"),
    expand(os.path.join(rgi_dir, "{sample}","contigs","{sample}_rgi.txt"), sample=SAMPLES),
    expand(os.path.join(rgi_dir, "{sample}","contigs","{sample}_rgi.json"), sample=SAMPLES),
    os.path.join(rgi_dir, "table","rgi_merged.tsv"),
]

# AntiSMASH - Biosynthetic gene clusters (requires metaspades)
targets["antismash"] = [
    expand(os.path.join(antismash_dir, "{sample}",".antismash_complete"), sample=SAMPLES),
    os.path.join(antismash_dir, "table","antismash_summary.tsv"),
]

# hecatomb contig annotation
targets["hecatomb"] = [
    expand(os.path.join(hecatomb_dir, "{sample}.hecatomb.tsv"), sample=SAMPLES)
]
