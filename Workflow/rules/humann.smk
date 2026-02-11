rule dl_humann_chocophlan:
    output:
        directory(humannDB_dir + "/chocophlan")
    conda:
        workflow.basedir + '/Workflow/envs/humann.yaml'
    params:
        db_dir = humannDB_dir + "/chocophlan"
    resources:
        mem_mb = 4000,
        time = 480
    threads: 1
    log:
        log_dir + "/humann/chocophlan_dl.log"
    shell:
        "humann_databases --download chocophlan full {params.db_dir} 2> {log}"

rule dl_humann_uniref:
    output:
        directory(humannDB_dir + "/uniref")
    conda:
        workflow.basedir + '/Workflow/envs/humann.yaml'
    params:
        db_dir = humannDB_dir + "/uniref"
    resources:
        mem_mb = 4000,
        time = 480
    threads: 1
    log:
        log_dir + "/humann/uniref_dl.log"
    shell:
        "humann_databases --download uniref uniref90_diamond {params.db_dir} 2> {log}"

rule dl_humann_utility:
    output:
        directory(humannDB_dir + "/utility_mapping")
    conda:
        workflow.basedir + '/Workflow/envs/humann.yaml'
    params:
        db_dir = humannDB_dir + "/utility_mapping"
    resources:
        mem_mb = 4000,
        time = 120
    threads: 1
    log:
        log_dir + "/humann/utility_dl.log"
    shell:
        "humann_databases --download utility_mapping full {params.db_dir} 2> {log}"

## Run HUMAnN3 on forward reads only
rule humann:
    input:
        r1           = nohuman_dir + "/{sample}_R1_001.fastq.gz",
        profile      = metaphlan_dir + "/{sample}_profile.txt",
        chocophlan   = humannDB_dir + "/chocophlan",
        uniref       = humannDB_dir + "/uniref",
        utility      = humannDB_dir + "/utility_mapping"
    output:
        genefamilies  = humann_dir + "/{sample}/{sample}_R1_001_genefamilies.tsv",
        pathabundance = humann_dir + "/{sample}/{sample}_R1_001_pathabundance.tsv",
        pathcoverage  = humann_dir + "/{sample}/{sample}_R1_001_pathcoverage.tsv"
    conda:
        workflow.basedir + "/Workflow/envs/humann.yaml"
    params:
        outdir  = humann_dir + "/{sample}",
        nucdb   = humannDB_dir + "/chocophlan",
        protdb  = humannDB_dir + "/uniref",
        mpa_db  = metaphlanDB_dir
    threads: 8
    resources:
        mem_mb = 64000,
        time = 1440
    log:
        log_dir + "/humann/{sample}.log"
    shell:
        """
        humann \
            --input {input.r1} \
            --output {params.outdir} \
            --taxonomic-profile {input.profile} \
            --nucleotide-database {params.nucdb} \
            --protein-database {params.protdb} \
            --metaphlan-options "--bowtie2db {params.mpa_db} --index mpa_vJan25_CHOCOPhlAnSGB_202503 -t rel_ab" \
            --threads {threads} \
            --memory-use maximum 2> {log}
        """

## Merge, normalise, and split stratified tables
rule humann_merge_tables:
    input:
        genefamilies  = expand(humann_dir + "/{sample}/{sample}_R1_001_genefamilies.tsv",  sample=SAMPLES),
        pathabundance = expand(humann_dir + "/{sample}/{sample}_R1_001_pathabundance.tsv", sample=SAMPLES),
        pathcoverage  = expand(humann_dir + "/{sample}/{sample}_R1_001_pathcoverage.tsv",  sample=SAMPLES)
    output:
        gf_cpm_unstrat = humann_dir + "/table/genefamilies_cpm_unstratified.tsv",
        pa_cpm_unstrat = humann_dir + "/table/pathabundance_cpm_unstratified.tsv",
        pc_unstrat     = humann_dir + "/table/pathcoverage_unstratified.tsv"
    conda:
        workflow.basedir + "/Workflow/envs/humann.yaml"
    params:
        humann_dir = humann_dir,
        gf_dir = humann_dir + "/table/genefamilies",
        pa_dir = humann_dir + "/table/pathabundance",
        pc_dir = humann_dir + "/table/pathcoverage"
    resources:
        mem_mb = 8000,
        time = 60
    log:
        log_dir + "/humann/merge_tables.log"
    shell:
        """
        mkdir -p {params.gf_dir} {params.pa_dir} {params.pc_dir}

        humann_join_tables -i {params.humann_dir} -o {params.gf_dir}/joined.tsv --file_name genefamilies 2> {log}
        humann_join_tables -i {params.humann_dir} -o {params.pa_dir}/joined.tsv --file_name pathabundance 2>> {log}
        humann_join_tables -i {params.humann_dir} -o {params.pc_dir}/joined.tsv --file_name pathcoverage 2>> {log}

        humann_renorm_table -i {params.gf_dir}/joined.tsv -o {params.gf_dir}/joined_cpm.tsv --units cpm 2>> {log}
        humann_renorm_table -i {params.pa_dir}/joined.tsv -o {params.pa_dir}/joined_cpm.tsv --units cpm 2>> {log}

        humann_split_stratified_table -i {params.gf_dir}/joined_cpm.tsv -o {params.gf_dir} 2>> {log}
        humann_split_stratified_table -i {params.pa_dir}/joined_cpm.tsv -o {params.pa_dir} 2>> {log}
        humann_split_stratified_table -i {params.pc_dir}/joined.tsv     -o {params.pc_dir} 2>> {log}

        cp {params.gf_dir}/joined_cpm_unstratified.tsv {output.gf_cpm_unstrat}
        cp {params.pa_dir}/joined_cpm_unstratified.tsv {output.pa_cpm_unstrat}
        cp {params.pc_dir}/joined_unstratified.tsv     {output.pc_unstrat}
        """