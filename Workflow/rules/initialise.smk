## Declare Directories
# Databases
DB_dir = config['databaseDirectory']
nohumanDB_dir = DB_dir + "/nohuman/HPRC.r2/db"
metaphlanDB_dir = DB_dir + "/metaphlan"
singlemDB_dir = DB_dir + "/singlem"
# File locations
input_dir = config['rawFastQDirectory']
clean_dir = config['trimmedFastQDirectory']
nohuman_dir = config['nohumanDirectory']
metaphlan_dir = config['metaphlanDirectory']
singlem_dir = config['singlemDirectory']
multiqc_dir = config['multiQCDirectory']
# Read SRA IDs from file if it exists
import os
SRA_IDS = []
if os.path.exists("sra_id.txt"):
    with open("sra_id.txt", "r") as f:
        SRA_IDS = [line.strip() for line in f if line.strip()]
# Quality Control
qc_dir = config['qcOutputDirectory']
raw_qc_dir = qc_dir + "/Step_1_Raw"
fastp_qc_dir = qc_dir + "/Step_2_FastP"
nohuman_qc_dir = qc_dir + "/Step_3_NoHuman"
# Log
log_dir = config['logDirectory']

# Flags
run_metaphlan = str(config.get("metaphlan", True)).lower() not in ("false", "0", "no")
run_singlem = str(config.get("singlem", True)).lower() not in ("false", "0", "no")

# Recognise file patterns
samples_standard, = glob_wildcards(input_dir + "/{sample}_R1_001.fastq.gz") # SAGC
samples_srr, = glob_wildcards(input_dir + "/{sample}_1.fastq.gz") # SRA

# All samples (combination of both)
SAMPLES = list(set(samples_standard + samples_srr + SRA_IDS))

## Rule to standardize SRR filenames
rule standardize_filenames:
    input:
        r1 = input_dir + "/{sample}_1.fastq.gz",
        r2 = input_dir + "/{sample}_2.fastq.gz"
    output:
        r1 = input_dir + "/{sample}_R1_001.fastq.gz",
        r2 = input_dir + "/{sample}_R2_001.fastq.gz"
    log:
        log_dir + "/file_rename/{sample}.log"
    shell:
        """
        mv {input.r1} {output.r1}
        mv {input.r2} {output.r2} 2> {log}
        """