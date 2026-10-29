## SingleM metapackage version — update this single line when SingleM releases a new metapackage
SINGLEM_METAPACKAGE = "S6.5.0.GTDB_r232.metapackage_20260319.smpkg.zb"

## Download SingleM Database
rule dl_singlem_DB:
    params:
        db_dir = singlemDB_dir
    output:
        directory(singlemDB_dir + "/" + SINGLEM_METAPACKAGE)
    conda: 
        workflow.basedir + '/Workflow/envs/singlem.yaml'
    container:
        get_container("singlem")
    resources:
        mem_mb = get_mem("dl_singlem_DB"),
        runtime = 480,
        db_download = 1
    threads: 2
    log:
        log_dir + "/singlem/databaseDL.log"
    shell:
       "singlem data --output-directory {params.db_dir} 2> {log}"

## Run SingleM
# Outputs profile and OTU table
rule singlem_profile:
    input:
        r1 = reads_dir + "/{sample}_R1_001.fastq.gz",
        r2 = reads_dir + "/{sample}_R2_001.fastq.gz",
        db = ancient(singlemDB_dir + "/" + SINGLEM_METAPACKAGE)
    output:
        profile = singlem_dir + "/{sample}_profile.tsv",
        otu_table = singlem_dir + "/{sample}_otu-table.tsv"
    conda:
        workflow.basedir + "/Workflow/envs/singlem.yaml"
    container:
        get_container("singlem")
    params:
        db_dir = singlemDB_dir
    threads: get_threads("singlem")
    resources:
        mem_mb = get_mem("singlem_profile"),
        runtime = 1400 
    log:
        log_dir + "/singlem/{sample}_profile.log"
    shell:
        """
        singlem pipe \
            --metapackage "{input.db}" \
            -1 {input.r1} -2 {input.r2} \
            --threads {threads} \
            -p {output.profile} \
            --otu-table {output.otu_table} 2> {log}
        """

## Send profile to extract more data
# Utilise the profile made earlier and outputs species abundance, abundance in longform, and a microbial fraction 
rule singlem_extra:
    input:
        r1 = reads_dir + "/{sample}_R1_001.fastq.gz",
        r2 = reads_dir + "/{sample}_R2_001.fastq.gz",
        db = ancient(singlemDB_dir + "/" + SINGLEM_METAPACKAGE),
        profile = singlem_dir + "/{sample}_profile.tsv"
    output:
        species_by_site = singlem_dir + "/{sample}_species_by_site.tsv",
        longform = singlem_dir + "/{sample}_longform.tsv",
        microbial_fraction = singlem_dir + "/{sample}.spf.tsv"
    conda:
        workflow.basedir + "/Workflow/envs/singlem.yaml"
    container:
        get_container("singlem")
    threads: get_threads("singlem")
    resources:
        mem_mb = get_mem("singlem_extra"),
        runtime = 480
    log:
        log_dir + "/singlem/{sample}_extra.log"
    shell:
        """
        if grep -q "s__" {input.profile}; then
            singlem summarise \
                --input-taxonomic-profile {input.profile} \
                --output-species-by-site-relative-abundance {output.species_by_site} \
                --output-species-by-site-level species >> {log} 2>&1
        else
            sample_name=$(awk 'NR==2 {{print $1}}' {input.profile})
            if [ -z "$sample_name" ]; then sample_name="{wildcards.sample}"; fi
            echo "No species-level assignments in {input.profile}; wrote unassigned-only table" >> {log}
            printf 'taxonomy\\t%s\\nunassigned\\t100.0\\n' "$sample_name" > {output.species_by_site}
        fi
        """

rule singlem_merged_table:
    input:
        profiles = expand(singlem_dir + "/{sample}_profile.tsv", sample=SAMPLES)
    output:
        merged = singlem_dir + "/table/merged_profile.tsv",
        species_by_site = directory(singlem_dir + "/table/species_by_site/")
    conda:
        workflow.basedir + "/Workflow/envs/singlem.yaml"
    container:
        get_container("singlem")
    log:
        log_dir + "/singlem/merge_table.log"
    resources:
        mem_mb = get_mem("singlem_merged_table"),
        runtime = 120
    threads: 2
    shell:
        """
        mkdir -p {singlem_dir}/table
        mkdir -p {singlem_dir}/table/species_by_site
        
        singlem summarise \
            --input-taxonomic-profiles {input.profiles} \
            --output-taxonomic-profile {output.merged} 2> {log}
        
        singlem summarise \
            --input-taxonomic-profiles {input.profiles} \
            --output-species-by-site-relative-abundance-prefix {output.species_by_site}/merged \
            2>> {log}
        """
        
## Merge prokaryotic fraction tables across all samples
rule singlem_merge_prokaryotic_fraction:
    input:
        spf_files = expand(singlem_dir + "/{sample}.spf.tsv", sample=SAMPLES)
    output:
        merged = singlem_dir + "/table/merged_prokaryotic_fraction.tsv"
    log:
        log_dir + "/singlem/merge_prokaryotic_fraction.log"
    resources:
        mem_mb = get_mem("singlem_merge_prokaryotic_fraction"),
        time = 60
    threads: 2
    shell:
        """
        mkdir -p $(dirname {output.merged})

        head -1 $(echo {input.spf_files} | tr ' ' '\\n' | head -1) > {output.merged}

        for f in {input.spf_files}; do
            tail -n +2 "$f" >> {output.merged}
        done

        total=$(( $(wc -l < {output.merged}) - 1 ))
        nfiles=$(echo {input.spf_files} | wc -w)
        echo "Merged prokaryotic fraction from $nfiles samples ($total rows)" > {log}
        """