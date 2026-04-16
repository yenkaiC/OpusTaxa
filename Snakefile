import os

configfile: os.path.join("config","config.yaml")
configfile: os.path.join("config","hecatomb","config.yaml")

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
include: os.path.join(workflow.basedir, "Workflow","rules","hecatomb.smk")



## Define Outputs
rule all:
    input:
        targets["qc"],
        targets["singlem"] if run_singlem else None,
        targets["metaphlan"] if run_metaphlan else None,
        targets["strainphlan"] if run_strainphlan else None,
        targets["kraken2"] if run_kraken2 else None,
        targets["metaspades"] if run_metaspades else None,
        targets["mlp"] if run_mlp else None,
        targets["human"] if run_humann else None,
        targets["rgi"] if run_rgi else None,
        targets["antismash"] if run_antismash else None,
        targets["hecatomb"] if run_hecatomb else None,



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