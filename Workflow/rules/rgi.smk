## RGI (Resistance Gene Identifier) - CARD Database Integration
## Contig-based annotation (requires metaSPAdes)

## Download CARD + WildCARD databases
# All rgi load operations happen here so downstream rules just need the checkpoint.
rule dl_card_DB:
    output:
        checkpoint = DB_dir + "/card/.download_complete"
    conda:
        workflow.basedir + '/Workflow/envs/rgi.yaml'
    params:
        db_dir = DB_dir + "/card"
    resources:
        mem_mb = 6000,
        time = 120
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

        # Only download if card.json is missing
        if [ ! -f "card.json" ]; then
            # Clean any previous RGI data
            rgi clean --local 2>> "$LOGFILE" || true

            # Download and extract CARD data
            wget -O data.tar.bz2 https://card.mcmaster.ca/latest/data 2>> "$LOGFILE"
            tar -xjf data.tar.bz2 2>> "$LOGFILE"
            rm -f data.tar.bz2

            # Download and extract WildCARD data
            wget -O wildcard_data.tar.bz2 https://card.mcmaster.ca/latest/variants 2>> "$LOGFILE"
            mkdir -p wildcard
            tar -xjf wildcard_data.tar.bz2 -C wildcard 2>> "$LOGFILE"
            gunzip wildcard/*.gz 2>> "$LOGFILE" || true
            rm -f wildcard_data.tar.bz2
        else
            echo "CARD database already exists (card.json found), skipping download" >> "$LOGFILE"
        fi

        # Always (re)load to ensure RGI's local index is current
        rgi load --card_json card.json --local 2>> "$LOGFILE"

        if [ -f "wildcard/index-for-model-sequences.txt" ]; then
            rgi load \
                --card_json card.json \
                --wildcard_index wildcard/index-for-model-sequences.txt \
                --amr_kmers wildcard/all_amr_61mers.txt \
                --kmer_database wildcard/61_kmer_db.json \
                --kmer_size 61 \
                --local 2>> "$LOGFILE"
        fi

        cd "$WORKDIR"
        touch {output.checkpoint}
        """

## Contig-based RGI (requires metaSPAdes)
# Runs rgi main from the CARD database directory so --local finds the loaded DB.
rule rgi_contigs:
    input:
        fasta = metaspades_dir + "/{sample}/contigs.fasta",
        db = DB_dir + "/card/.download_complete"
    output:
        txt = rgi_dir + "/{sample}/contigs/{sample}_rgi.txt",
        json = rgi_dir + "/{sample}/contigs/{sample}_rgi.json"
    conda:
        workflow.basedir + "/Workflow/envs/rgi.yaml"
    params:
        db_dir = DB_dir + "/card",
        out_prefix = lambda wc: os.path.abspath(rgi_dir + "/" + wc.sample + "/contigs/" + wc.sample + "_rgi")
    threads: 8
    resources:
        mem_mb = 40000,
        time = 960
    log:
        log_dir + "/rgi/{sample}_contigs.log"
    shell:
        """
        mkdir -p {rgi_dir}/{wildcards.sample}/contigs

        WORKDIR=$(pwd)
        LOGFILE="$WORKDIR/{log}"
        INPUT_FASTA="$WORKDIR/{input.fasta}"

        cd {params.db_dir}

        rgi main \
            --input_sequence "$INPUT_FASTA" \
            --output_file {params.out_prefix} \
            --input_type contig \
            --local \
            --clean \
            --num_threads {threads} \
            --alignment_tool DIAMOND 2> "$LOGFILE"

        cd "$WORKDIR"
        """