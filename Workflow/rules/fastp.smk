# Declare FastP inputs, outputs and shellscript
rule fastp_trim:
    input: 
        r1 = input_dir + "/{sample}_R1_001.fastq.gz",
        r2 = input_dir + "/{sample}_R2_001.fastq.gz"
    output: 
        r1 = clean_dir + "/{sample}_R1_001.fastq.gz",
        r2 = clean_dir + "/{sample}_R2_001.fastq.gz"
    conda: 
        '../envs/fastp.yaml'
    shell:
        "fastp -i {input.r1} -I {input.r2} -o {output.r1} -O {output.r2}"