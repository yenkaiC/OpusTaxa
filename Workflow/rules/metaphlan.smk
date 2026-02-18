## Download metaphylan Database
rule dl_metaphlan_DB:
    output: 
        done = metaphlanDB_dir + "/.download_complete"
    conda: 
        workflow.basedir + '/Workflow/envs/metaphlan.yaml'
    resources:
        mem_mb = 16000,
        time = 1440
    threads: 1
    params:
        db_dir = metaphlanDB_dir
    log:
        log_dir + "/metaphlan/databaseDL.log"
    shell:
        """
        metaphlan --install --db_dir {params.db_dir} 2> {log}
        touch {output.done}
        """

## Run MetaPhlAn
# outputs a bowtie and an abundance profile file
rule metaphlan:
    input:
        r1 = nohuman_dir + "/{sample}_R1_001.fastq.gz",
        r2 = nohuman_dir + "/{sample}_R2_001.fastq.gz",
        db = metaphlanDB_dir + "/.download_complete"
    output:
        profile = metaphlan_dir + "/{sample}_profile.txt",
        bowtie = metaphlan_dir + "/{sample}_bowtie.bz2"
    conda:
        workflow.basedir + "/Workflow/envs/metaphlan.yaml"
    params:
        db_dir = metaphlanDB_dir
    threads: 6
    log:
        log_dir + "/metaphlan/{sample}.log"
    resources:
        mem_mb = 38000,
        time = 720
    shell:
        """
        metaphlan {input.r1},{input.r2} \
            --input_type fastq \
            --nproc {threads} \
            --index "mpa_vJan25_CHOCOPhlAnSGB_202503" \
            --db_dir {params.db_dir} \
            --mapout {output.bowtie} \
            -o {output.profile} \
            -t rel_ab_w_read_stats 2> {log}
        """

rule metaphlan_abundance_table:
    input:
        profiles = expand(metaphlan_dir + "/{sample}_profile.txt", sample=SAMPLES)
    output:
        abundance = metaphlan_dir + "/table/abundance_all.txt",
        species = metaphlan_dir + "/table/abundance_species.txt"
    conda:
        workflow.basedir + "/Workflow/envs/metaphlan.yaml"
    log:
        log_dir + "/metaphlan/merge_table.log"
    shell:
        """
        # Create output directory if it doesn't exist
        mkdir -p {metaphlan_dir}/table

        # Merge all the tables into one
        merge_metaphlan_tables.py {input.profiles} > {output.abundance} 2> {log}
        
        # Extract header (line 2) and species rows
        sed -n '2p' {output.abundance} > {output.species}
        grep "s__" {output.abundance} >> {output.species} 2>> {log}
        """
    