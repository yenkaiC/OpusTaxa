rule antismash_download_databases:
    output:
        touch("Database/antismash/.databases_downloaded")
    log:
        "logs/antismash/download_databases.log"
    conda:
        "../envs/antismash.yaml"
    shell:
        """
        download-antismash-databases 2> {log}
        """

rule antismash_contigs:
    input:
        fasta="Data/MetaSPAdes/{sample}/contigs.fasta",
        db="Database/antismash/.databases_downloaded"
    output:
        html="Data/AntiSMASH/{sample}/index.html",
        gbk="Data/AntiSMASH/{sample}/contigs.gbk",
        json="Data/AntiSMASH/{sample}/contigs.json",
        complete=touch("Data/AntiSMASH/{sample}/.antismash_complete")
    log:
        "logs/antismash/{sample}.log"
    conda:
        "../envs/antismash.yaml"
    threads: 8
    shell:
        """
        antismash \
            --taxon bacteria \
            --output-dir Data/AntiSMASH/{wildcards.sample} \
            --genefinding-tool prodigal-m \
            --cpus {threads} \
            Data/MetaSPAdes/{wildcards.sample}/contigs.fasta 2> {log}
        """