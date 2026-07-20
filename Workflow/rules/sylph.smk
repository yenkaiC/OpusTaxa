## Sylph - ultrafast taxonomic profiling via abundance-corrected minhash
## Runs on host-removed reads (requires nohuman)
## Uses the pre-built GTDB-R220 database + sylph-tax for taxonomic labels

sylph_dir = config.get('sylphDirectory', 'Data/Sylph')
sylphDB_dir = DB_dir + "/sylph"
run_sylph = str(config.get("sylph", False)).lower() not in ("false", "0", "no")

# Database filename (GTDB-R220, c200). Override in config if using another db.
SYLPH_DB_NAME = config.get("sylph_db_name", "gtdb-r220-c200-dbv1.syldb")
SYLPH_DB_URL  = config.get("sylph_db_url",
                           "http://faust.compbio.cs.cmu.edu/sylph-stuff/gtdb-r220-c200-dbv1.syldb")
# sylph-tax metadata name for taxonomic integration (matches the db above)
SYLPH_TAX_NAME = config.get("sylph_tax_name", "GTDB_r220")


## Download the pre-built sylph database
rule dl_sylph_DB:
    output:
        db = sylphDB_dir + "/" + SYLPH_DB_NAME
    conda:
        workflow.basedir + "/Workflow/envs/sylph.yaml"
    container:
        get_container("sylph")
    params:
        db_dir = sylphDB_dir,
        url = SYLPH_DB_URL
    resources:
        mem_mb = 12000,
        runtime = 360
    threads: 2
    log:
        log_dir + "/sylph/database_dl.log"
    shell:
        """
        mkdir -p {params.db_dir}
        mkdir -p $(dirname {log})
        if [ ! -f "{output.db}" ]; then
            wget -O {output.db} {params.url} 2> {log}
        else
            echo "Sylph database already exists, skipping download" > {log}
        fi
        """


## Download sylph-tax taxonomy metadata (for taxonomic labelling)
rule dl_sylph_tax:
    output:
        checkpoint = sylphDB_dir + "/.sylph_tax_downloaded"
    conda:
        workflow.basedir + "/Workflow/envs/sylph.yaml"
    container:
        get_container("sylph")
    params:
        tax_dir = sylphDB_dir + "/sylph-tax"
    resources:
        mem_mb = 6000,
        runtime = 120
    threads: 2
    log:
        log_dir + "/sylph/sylph_tax_dl.log"
    shell:
        """
        mkdir -p {params.tax_dir}
        mkdir -p $(dirname {log})
        sylph-tax download --download-to {params.tax_dir} 2> {log}
        touch {output.checkpoint}
        """


## Sketch reads (per sample). Sketching is separated so profiling is fast and
## can be re-run against different databases without re-reading FASTQs.
rule sylph_sketch:
    input:
        r1 = nohuman_dir + "/{sample}_R1_001.fastq.gz",
        r2 = nohuman_dir + "/{sample}_R2_001.fastq.gz"
    output:
        sketch = sylph_dir + "/sketches/{sample}.paired.sylsp"
    conda:
        workflow.basedir + "/Workflow/envs/sylph.yaml"
    container:
        get_container("sylph")
    params:
        outdir = sylph_dir + "/sketches"
    threads: get_threads("sylph")
    resources:
        mem_mb = 24000,
        runtime = 240
    log:
        log_dir + "/sylph/{sample}_sketch.log"
    shell:
        """
        mkdir -p {params.outdir}
        mkdir -p $(dirname {log})
        sylph sketch \
            -1 {input.r1} -2 {input.r2} \
            -t {threads} \
            -d {params.outdir} \
            -S {wildcards.sample} 2> {log}
        """


## Profile a sample against the database
rule sylph_profile:
    input:
        sketch = sylph_dir + "/sketches/{sample}.paired.sylsp",
        db = sylphDB_dir + "/" + SYLPH_DB_NAME
    output:
        profile = sylph_dir + "/{sample}_profile.tsv"
    conda:
        workflow.basedir + "/Workflow/envs/sylph.yaml"
    container:
        get_container("sylph")
    threads: get_threads("sylph")
    resources:
        mem_mb = 28000,
        runtime = 360
    log:
        log_dir + "/sylph/{sample}_profile.log"
    shell:
        """
        mkdir -p $(dirname {output.profile})
        mkdir -p $(dirname {log})
        sylph profile \
            {input.db} \
            {input.sketch} \
            -t {threads} \
            -o {output.profile} 2> {log}
        """


## Add taxonomic labels to the profile using sylph-tax
rule sylph_taxprof:
    input:
        profile = sylph_dir + "/{sample}_profile.tsv",
        tax = sylphDB_dir + "/.sylph_tax_downloaded"
    output:
        taxprof = sylph_dir + "/{sample}_taxprof.tsv"
    conda:
        workflow.basedir + "/Workflow/envs/sylph.yaml"
    container:
        get_container("sylph")
    params:
        tax_name = SYLPH_TAX_NAME,
        prefix = sylph_dir + "/{sample}_taxprof"
    resources:
        mem_mb = 12000,
        runtime = 120
    threads: 2
    log:
        log_dir + "/sylph/{sample}_taxprof.log"
    shell:
        """
        mkdir -p $(dirname {output.taxprof})
        mkdir -p $(dirname {log})
        sylph-tax taxprof \
            {input.profile} \
            -t {params.tax_name} \
            -o {params.prefix} 2> {log}

        # sylph-tax appends a suffix; normalise to the expected output name
        if [ ! -f "{output.taxprof}" ]; then
            produced=$(ls {params.prefix}* 2>/dev/null | head -1)
            if [ -n "$produced" ]; then mv "$produced" {output.taxprof}; fi
        fi
        """


## Merge all taxonomic profiles into one table
rule sylph_merge:
    input:
        taxprofs = expand(sylph_dir + "/{sample}_taxprof.tsv", sample=SAMPLES)
    output:
        merged = sylph_dir + "/table/sylph_merged_abundance.tsv"
    conda:
        workflow.basedir + "/Workflow/envs/sylph.yaml"
    container:
        get_container("sylph")
    resources:
        mem_mb = 20000,
        runtime = 60
    threads: 2
    log:
        log_dir + "/sylph/merge.log"
    shell:
        """
        mkdir -p $(dirname {output.merged})
        mkdir -p $(dirname {log})
        sylph-tax merge {input.taxprofs} -o {output.merged} 2> {log}
        """
