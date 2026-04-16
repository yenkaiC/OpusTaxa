## Download nohuman's Database. 
rule dl_noHuman_DB:
    output:
        nohumanDB_dir + "/taxo.k2d",
        nohumanDB_dir + "/hash.k2d",
        nohumanDB_dir + "/opts.k2d"
    conda: 
        '../envs/nohuman.yaml'
    container:
        get_container("nohuman")
    params:
        db_dir = DB_dir + "/nohuman"
    resources:
        mem_mb = 10000,
        runtime = 480
    threads: 2
    log:
        log_dir + "/nohuman/databaseDL.log"
    shell:
        "nohuman --download --db {params.db_dir} 2> {log}"
        #""" # before update
        #mkdir -p {params}
        #curl -L https://ndownloader.figshare.com/files/59658306 -o {params}/nohuman_db.tar.gz
        #tar -xzvf {params}/nohuman_db.tar.gz -C {params}
        #rm {params}/nohuman_db.tar.gz
        #"""

## Run nohuman
rule remove_human_reads:
    input:
        r1 = clean_dir + "/{sample}_R1_001.fastq.gz",
        r2 = clean_dir + "/{sample}_R2_001.fastq.gz",
        db_taxo = nohumanDB_dir + "/taxo.k2d",
        db_hash = nohumanDB_dir + "/hash.k2d",
        db_opts = nohumanDB_dir + "/opts.k2d"
    output:
        r1 = nohuman_dir + "/{sample}_R1_001.fastq.gz",
        r2 = nohuman_dir + "/{sample}_R2_001.fastq.gz"
    priority: 50
    conda: 
        '../envs/nohuman.yaml'
    container:
        get_container("nohuman")
    threads: get_threads("nohuman")
    log:
        log_dir + "/nohuman/{sample}.log"
    params:
        db_dir = nohumanDB_dir
    resources:
        mem_mb = 32000, #32GB
        runtime = 480
    shell:
        "nohuman --db {params.db_dir} -t {threads} --out1 {output.r1} --out2 {output.r2} {input.r1} {input.r2} 2> {log}"

## Summarise human read removal stats from NoHuman logs
rule nohuman_summary:
    input:
        logs = expand(log_dir + "/nohuman/{sample}.log", sample=SAMPLES)
    output:
        summary = nohuman_dir + "/nohuman_summary.tsv"
    log:
        log_dir + "/nohuman/summary.log"
    resources:
        mem_mb = 6000,
        runtime = 30
    threads: 1
    shell:
        """
        echo -e "sample\ttotal_reads\thuman_reads\thuman_percent\tnonhuman_reads\tnonhuman_percent" > {output.summary}

        for f in {input.logs}; do
            sample=$(basename "$f" .log)

            line=$(grep "sequences classified as human" "$f" 2>/dev/null || true)

            if [ -n "$line" ]; then
                human=$(echo "$line" | grep -oP '\\b[0-9,]+ / ' | sed 's/ \/ //' | tr -d ',')
                total=$(echo "$line" | grep -oP '/ [0-9,]+ ' | sed 's/[/ ]//g' | tr -d ',')
                human_pct=$(echo "$line" | grep -oP '\\([0-9.]+%\\)' | head -1 | tr -d '()')
                nonhuman=$(echo "$line" | grep -oP '[0-9,]+ \\(' | tail -1 | grep -oP '[0-9,]+' | tr -d ',')
                nonhuman_pct=$(echo "$line" | grep -oP '\\([0-9.]+%\\)' | tail -1 | tr -d '()')

                echo -e "${{sample}}\t${{total}}\t${{human}}\t${{human_pct}}\t${{nonhuman}}\t${{nonhuman_pct}}" >> {output.summary}
            else
                echo -e "${{sample}}\tNA\tNA\tNA\tNA\tNA" >> {output.summary}
            fi
        done

        echo "Summarised $(wc -l < {output.summary}) samples" > {log}
        """