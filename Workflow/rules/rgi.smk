## Download CARD Database
rule dl_card_DB:
    output:
        json     = DB_dir + "/card/card.json",
        wildcard = DB_dir + "/card/wildcard/index-for-model-sequences.txt",
        marker   = touch(DB_dir + "/card/.rgi_downloaded")
    conda:
        workflow.basedir + '/Workflow/envs/rgi.yaml'
    params:
        db_dir = DB_dir + "/card"
    resources:
        mem_mb = 16000,
        time   = 120
    threads: 1
    log:
        log_dir + "/rgi/card_db_download.log"
    shell:
        """
        mkdir -p $(dirname {log})
        mkdir -p {params.db_dir}
        WORKDIR=$(pwd)
        LOGFILE="$WORKDIR/{log}"
        cd {params.db_dir}

        rgi clean --local 2>> "$LOGFILE" || true

        wget -O data.tar.bz2 https://card.mcmaster.ca/latest/data 2>> "$LOGFILE"
        tar -xjf data.tar.bz2 2>> "$LOGFILE"

        wget -O wildcard_data.tar.bz2 https://card.mcmaster.ca/latest/variants 2>> "$LOGFILE"
        mkdir -p wildcard
        tar -xjf wildcard_data.tar.bz2 -C wildcard 2>> "$LOGFILE"
        gunzip wildcard/*.gz 2>> "$LOGFILE" || true

        rm -f data.tar.bz2 wildcard_data.tar.bz2
        cd "$WORKDIR"

        touch {output.marker}
        """

## Load CARD Database
rule rgi_load_db:
    input:
        json = DB_dir + "/card/card.json",
        downloaded = DB_dir + "/card/.rgi_downloaded"
    output:
        touch(DB_dir + "/card/.rgi_loaded")
    conda:
        workflow.basedir + '/Workflow/envs/rgi.yaml'
    log:
        log_dir + "/rgi/load_db.log"
    shell:
        """
        rgi load \
            --card_json {input.json} \
            --local 2> {log}
        """

## Contigs
rule rgi_contigs:
    input:
        fasta = "Data/MetaSPAdes/{sample}/contigs.fasta",
        db    = DB_dir + "/card/.rgi_loaded"
    output:
        txt  = "Data/RGI/{sample}/contigs/{sample}_rgi.txt",
        json = "Data/RGI/{sample}/contigs/{sample}_rgi.json"
    log:
        log_dir + "/rgi/{sample}_contigs.log"
    conda:
        workflow.basedir + '/Workflow/envs/rgi.yaml'
    threads: 8
    resources:
        mem_mb  = 40000,
        runtime = 960
    shell:
        """
        mkdir -p Data/RGI/{wildcards.sample}/contigs
        rgi main \
            --input_sequence {input.fasta} \
            --output_file Data/RGI/{wildcards.sample}/contigs/{wildcards.sample}_rgi \
            --input_type contig \
            --local \
            --clean \
            --num_threads {threads} \
            --alignment_tool DIAMOND 2> {log}
        """