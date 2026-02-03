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
# Quality Control
qc_dir = config['qcOutputDirectory']
raw_qc_dir = qc_dir + "/Step_1_Raw"
fastp_qc_dir = qc_dir + "/Step_2_FastP"
nohuman_qc_dir = qc_dir + "/Step_3_NoHuman"
# Log
log_dir = 'logs'

# Recognise file patterns
samples_standard, = glob_wildcards(input_dir + "/{sample}_R1_001.fastq.gz") # SAGC
samples_srr, = glob_wildcards(input_dir + "/{sample}_1.fastq.gz") # SRA

# All samples (combination of both)
SAMPLES = list(set(samples_standard + samples_srr))

# Rule to standardize SRR filenames
rule standardize_filenames:
    input:
        r1 = input_dir + "/{sample}_1.fastq.gz",
        r2 = input_dir + "/{sample}_2.fastq.gz"
    output:
        r1 = input_dir + "/{sample}_R1_001.fastq.gz",
        r2 = input_dir + "/{sample}_R2_001.fastq.gz"
    shell:
        """
        mv {input.r1} {output.r1}
        mv {input.r2} {output.r2}
        """