## Declare FastP inputs, outputs and shellscript
rule fastp_trim:
    input: 
        r1 = input_dir + "/{sample}_R1_001.fastq.gz",
        r2 = input_dir + "/{sample}_R2_001.fastq.gz"
    output: 
        r1 = clean_dir + "/{sample}_R1_001.fastq.gz",
        r2 = clean_dir + "/{sample}_R2_001.fastq.gz"
    conda: 
        '../envs/fastp.yaml'
    threads:
        8
    resources:
        mem_mb = 32000, #32GB
        time = 480 # 8 hours
    log:
        log_dir + "/fastp/{sample}.log"
    shell:
        "fastp -i {input.r1} -I {input.r2} -o {output.r1} -O {output.r2} 2> {log}"