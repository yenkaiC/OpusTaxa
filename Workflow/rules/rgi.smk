## RGI (Resistance Gene Identifier) - CARD Database Integration
## Dual-mode approach: read-based screening + contig-based annotation

## Download CARD Database
rule dl_card_DB:
    output:
        json = DB_dir + "/card/card.json",
        wildcard = DB_dir + "/card/wildcard/index-for-model-sequences.txt"
    conda:
        workflow.basedir + '/Workflow/envs/rgi.yaml'
    params:
        db_dir = DB_dir + "/card"
    resources:
        mem_mb = 4000,
        time = 120
    threads: 1
    log:
        log_dir + "/rgi/card_db_download.log"
    shell:
        """
        # Create directories
        mkdir -p $(dirname {log})
        mkdir -p {params.db_dir}
        
        # Save absolute paths
        WORKDIR=$(pwd)
        LOGFILE="$WORKDIR/{log}"
        
        cd {params.db_dir}
        
        # Clean any previous RGI data
        rgi clean --local 2>> "$LOGFILE" || true
        
        # Download and extract CARD data
        wget -O data.tar.bz2 https://card.mcmaster.ca/latest/data 2>> "$LOGFILE"
        tar -xjf data.tar.bz2 2>> "$LOGFILE"
        
        # Download and extract WildCARD data
        wget -O wildcard_data.tar.bz2 https://card.mcmaster.ca/latest/variants 2>> "$LOGFILE"
        mkdir -p wildcard
        tar -xjf wildcard_data.tar.bz2 -C wildcard 2>> "$LOGFILE"
        gunzip wildcard/*.gz 2>> "$LOGFILE" || true
        
        # Load CARD database
        rgi load --card_json card.json --local 2>> "$LOGFILE"
        
        # Load wildcard data with kmer_size specified
        rgi load \
            --card_json card.json \
            --wildcard_index wildcard/index-for-model-sequences.txt \
            --amr_kmers wildcard/all_amr_61mers.txt \
            --kmer_database wildcard/61_kmer_db.json \
            --kmer_size 61 \
            --local 2>> "$LOGFILE"
        
        # Cleanup
        rm -f data.tar.bz2 wildcard_data.tar.bz2
        
        cd "$WORKDIR"
        """

## MODE 1: Read-based RGI (Fast screening)
rule rgi_reads:
    input:
        r1 = nohuman_dir + "/{sample}_R1_001.fastq.gz",
        r2 = nohuman_dir + "/{sample}_R2_001.fastq.gz",
        db_json = DB_dir + "/card/card.json",
        db_wildcard = DB_dir + "/card/wildcard/index-for-model-sequences.txt"
    output:
        txt = rgi_dir + "/{sample}/reads/{sample}_rgi.txt",
        json = rgi_dir + "/{sample}/reads/{sample}_rgi.json"
    conda:
        workflow.basedir + "/Workflow/envs/rgi.yaml"
    params:
        outdir = rgi_dir + "/{sample}/reads",
        prefix = "{sample}_rgi",
        r1_concat = rgi_dir + "/{sample}/reads/{sample}_concat.fastq"
    threads: 8
    resources:
        mem_mb = 32000,
        time = 480
    log:
        log_dir + "/rgi/{sample}_reads.log"
    shell:
        """
        # Create directories and save paths
        mkdir -p {params.outdir}
        mkdir -p $(dirname {log})
        
        WORKDIR=$(pwd)
        LOGFILE="$WORKDIR/{log}"
        
        # Concatenate reads (rgi main works better with single file)
        zcat {input.r1} {input.r2} > {params.r1_concat}
        
        cd {params.outdir}
        
        rgi main \
            --input_sequence "$WORKDIR/{params.r1_concat}" \
            --output_file {params.prefix} \
            --input_type read \
            --local \
            --clean \
            --num_threads {threads} \
            --alignment_tool DIAMOND 2> "$LOGFILE"
        
        # Clean up concatenated file
        rm -f "$WORKDIR/{params.r1_concat}"
        """

## MODE 2: Contig-based RGI (Detailed annotation - requires metaSPAdes)
# Load database
rule rgi_load_db:
    input:
        "Database/card/card.json"
    output:
        touch("Database/card/.rgi_loaded")  # marker file
    log:
        "logs/rgi/load_db.log"
    conda:
        "../envs/rgi.yaml"
    threads: 8
    resources:
        mem_mb = 32000,
        time = 480
    shell:
        """
        rgi load \
            --card_json {input} \
            --local 2> {log}
        """
# Contigs
rule rgi_contigs:
    input:
        fasta="Data/MetaSPAdes/{sample}/contigs.fasta",
        db="Database/card/.rgi_loaded"
    output:
        txt="Data/RGI/{sample}/contigs/{sample}_rgi.txt",
        json="Data/RGI/{sample}/contigs/{sample}_rgi.json"
    log:
        "logs/rgi/{sample}_contigs.log"
    conda:
        "../envs/rgi.yaml"
    threads: 8
    resources:
        mem_mb = 32000,
        time = 960
    shell:
        """
        mkdir -p Data/RGI/{wildcards.sample}/contigs
        
        rgi main \
            --input_sequence Data/MetaSPAdes/{wildcards.sample}/contigs.fasta \
            --output_file Data/RGI/{wildcards.sample}/contigs/{wildcards.sample}_rgi \
            --input_type contig \
            --local \
            --clean \
            --num_threads {threads} \
            --alignment_tool DIAMOND 2> {log}
        """