rule install_gutsmash:
    output:
        touch("Database/gutsmash/.installed")
    log:
        "logs/gutsmash/install.log"
    conda:
        "../envs/gutsmash.yaml"
    shell:
        """
        pip install git+https://github.com/victoriapascal/gutsmash.git 2> {log}
        """

rule gutsmash_contigs:
    input:
        fasta="Data/MetaSPAdes/{sample}/contigs.fasta",
        installed="Database/gutsmash/.installed"
    output:
        gbk="Data/GutSMASH/{sample}/contigs.gbk",
        json="Data/GutSMASH/{sample}/contigs.json",
        complete=touch("Data/GutSMASH/{sample}/.gutsmash_complete")
    log:
        "logs/gutsmash/{sample}.log"
    conda:
        "../envs/gutsmash.yaml"
    threads: 8
    shell:
        """
        gutsmash \
            --output-dir Data/GutSMASH/{wildcards.sample} \
            --genefinding-tool prodigal-m \
            --cpus {threads} \
            Data/MetaSPAdes/{wildcards.sample}/contigs.fasta 2> {log}
        """