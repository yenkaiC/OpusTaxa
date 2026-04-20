## Download SingleM Database
rule dl_singlem_DB:
    params:
        db_dir = singlemDB_dir
    output:
        directory(singlemDB_dir + "/S5.4.0.GTDB_r226.metapackage_20250331.smpkg.zb")
    conda: 
        workflow.basedir + '/Workflow/envs/singlem.yaml'
    container:
        get_container("singlem")
    resources:
        mem_mb = 10000,
        runtime = 480
    threads: 2
    log:
        log_dir + "/singlem/databaseDL.log"
    shell:
       "singlem data --output-directory {params.db_dir} 2> {log}"

## Run SingleM
# Outputs profile and OTU table
rule singlem_profile:
    input:
        r1 = nohuman_dir + "/{sample}_R1_001.fastq.gz",
        r2 = nohuman_dir + "/{sample}_R2_001.fastq.gz",
        db = singlemDB_dir + "/S5.4.0.GTDB_r226.metapackage_20250331.smpkg.zb"
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
        mem_mb = 40000,
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
        r1 = nohuman_dir + "/{sample}_R1_001.fastq.gz",
        r2 = nohuman_dir + "/{sample}_R2_001.fastq.gz",
        db = singlemDB_dir + "/S5.4.0.GTDB_r226.metapackage_20250331.smpkg.zb",
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
        mem_mb = 38000,
        runtime = 480
    log:
        log_dir + "/singlem/{sample}_profile.log"
    shell:
        """
        singlem summarise \
            --input-taxonomic-profile {input.profile} \
            --output-species-by-site-relative-abundance {output.species_by_site} \
            --output-species-by-site-level species 2>> {log}
        
        singlem summarise \
            --input-taxonomic-profile {input.profile} \
            --output-taxonomic-profile-with-extras {output.longform} 2>> {log}

        singlem prokaryotic_fraction \
            --forward {input.r1} --reverse {input.r2} \
            --metapackage "{input.db}" \
            -p {input.profile} > {output.microbial_fraction} 2>> {log}
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
        mem_mb = 10000,
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
        mem_mb = 12000,
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