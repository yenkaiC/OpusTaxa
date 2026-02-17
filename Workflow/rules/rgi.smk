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
        
        # Load wildcard data
        rgi load \
            --card_json card.json \
            --wildcard_index wildcard/index-for-model-sequences.txt \
            --amr_kmers wildcard/all_amr_61mers.txt \
            --kmer_database wildcard/61_kmer_db.json \
            --local 2>> "$LOGFILE"
        
        # Cleanup
        rm -f data.tar.bz2 wildcard_data.tar.bz2
        
        cd "$WORKDIR"
        """