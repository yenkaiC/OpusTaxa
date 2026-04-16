import os

configfile: os.path.join("config","config.yaml")

## Load rules
include: os.path.join(workflow.basedir, "Workflow","rules","initialise.smk")
include: os.path.join(workflow.basedir, "Workflow","rules","targets.smk")
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
        targets["qc"],
        targets["singlem"] if run_singlem,
        targets["metaphlan"] if run_metaphlan,
        targets["strainphlan"] if run_strainphlan,
        targets["kraken2"] if run_kraken2,
        targets["metaspades"] if run_metaspades,
        targets["mlp"] if run_mlp,
        targets["human"] if run_humann,
        targets["rgi"] if run_rgi,
        targets["antismash"] if run_antismash,



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