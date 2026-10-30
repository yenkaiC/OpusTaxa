## Download Kraken2 PlusPF-16 Database (16GB)
rule dl_kraken2_DB:
    output:
        checkpoint = kraken2DB_dir + "/.download_complete"
    conda:
        workflow.basedir + '/Workflow/envs/kraken2.yaml'
    container:
        get_container("kraken2")
    params:
        db_dir = kraken2DB_dir
    resources:
        mem_mb = get_mem("dl_kraken2_DB"),
        runtime = 480,
        db_download = 1
    threads: 4
    log:
        log_dir + "/kraken2/database_dl.log"
    shell:
        """
        if [ ! -f "{params.db_dir}/hash.k2d" ]; then
            mkdir -p {params.db_dir}
            # Includes: archaea, bacteria, viral, plasmid, human, UniVec_Core, protozoa, fungi
            wget -P {params.db_dir} https://genome-idx.s3.amazonaws.com/kraken/k2_pluspf_16_GB_20251015.tar.gz 2> {log}
            tar -xzvf {params.db_dir}/k2_pluspf_16_GB_20251015.tar.gz -C {params.db_dir} 2>> {log}
            rm {params.db_dir}/k2_pluspf_16_GB_20251015.tar.gz
        else
            echo "Kraken2 PlusPF-16 database already exists, skipping download" > {log}
        fi
        touch {output.checkpoint}
        """
# Choose your own database at https://benlangmead.github.io/aws-indexes/k2

## Run Kraken2 on paired-end reads
rule kraken2:
    input:
        r1 = reads_dir + "/{sample}_R1_001.fastq.gz",
        r2 = reads_dir + "/{sample}_R2_001.fastq.gz",
        db = ancient(kraken2DB_dir + "/.download_complete")
    output:
        report = kraken2_dir + "/{sample}_report.txt",
        output = temp(kraken2_dir + "/{sample}_output.txt")
    conda:
        workflow.basedir + "/Workflow/envs/kraken2.yaml"
    container:
        get_container("kraken2")
    params:
        db_dir = kraken2DB_dir
    threads: get_threads("kraken2")
    resources:
        mem_mb = get_mem("kraken2"),
        runtime = 480
    log:
        log_dir + "/kraken2/{sample}.log"
    shell:
        """
        kraken2 \
            --db {params.db_dir} \
            --threads {threads} \
            --paired {input.r1} {input.r2} \
            --report {output.report} \
            --output {output.output} \
            --gzip-compressed 2> {log}
        
        # a sample with no reads leaves kraken2 with nothing to report
        if [ ! -s {output.report} ]; then
            printf '100.00\t0\t0\tU\t0\tunclassified\n' > {output.report}
            echo "[kraken2] no reads classified; wrote empty report" >> {log}
        fi
        """

## Run Bracken for abundance estimation
rule bracken:
    input:
        report = kraken2_dir + "/{sample}_report.txt",
        db = ancient(kraken2DB_dir + "/.download_complete")
    output:
        bracken_out = kraken2_dir + "/{sample}_bracken.txt",
        bracken_report = kraken2_dir + "/{sample}_bracken_report.txt"
    conda:
        workflow.basedir + "/Workflow/envs/kraken2.yaml"
    container:
        get_container("kraken2")
    params:
        db_dir = kraken2DB_dir,
        read_len = get_param("bracken", "read_length", 150),
        level = get_param("bracken", "level", "S"),
        min_reads = BRACKEN_MIN_READS,
    threads: 4
    resources:
        mem_mb = get_mem("bracken"),
        runtime = 60
    log:
        log_dir + "/kraken2/{sample}_bracken.log"
    shell:
        """
        # --- guard: negative controls and shallow samples -------------------
        n=$(awk -F'\t' -v lvl="{params.level}" \
              '$4 == lvl {{ s += $2 }} END {{ print s+0 }}' {input.report})
        if [ "$n" -lt {params.min_reads} ]; then
            echo "[bracken] {wildcards.sample}: $n reads at level {params.level} (minimum {params.min_reads}) - skipping Bracken, writing empty table" >> {log}
            printf 'name\ttaxonomy_id\ttaxonomy_lvl\tkraken_assigned_reads\tadded_reads\tnew_est_reads\tfraction_total_reads\n' > {output.bracken}
            cp {input.report} {output.report}
            exit 0
        fi
        
        bracken \
            -d {params.db_dir} \
            -i {input.report} \
            -o {output.bracken_out} \
            -w {output.bracken_report} \
            -r {params.read_len} \
            -l {params.level} > {log} 2>&1
        """

## Combine Bracken reports across samples
rule combine_bracken_reports:
    input:
        expand(kraken2_dir + "/{sample}_bracken.txt", sample=SAMPLES)
    output:
        combined = kraken2_dir + "/table/combined_bracken_species.txt"
    conda:
        workflow.basedir + "/Workflow/envs/kraken2.yaml"
    container:
        get_container("kraken2")
    log:
        log_dir + "/kraken2/combine_reports.log"
    threads: 4
    params:
        files = lambda wc, input: " ".join(
            f for f in input.bracken if os.path.getsize(f) > 100
        ),
    resources:
        mem_mb = get_mem("combine_bracken_reports"),
        runtime = 60
    shell:
        """
        mkdir -p {kraken2_dir}/table
        combine_bracken_outputs.py \
            --files {input} \
            -o {output.combined} > {log} 2>&1
        """
