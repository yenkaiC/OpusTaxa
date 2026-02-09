## Download SingleM Database
rule dl_singlem_DB:
    params:
        db_dir = singlemDB_dir
    output:
        directory(singlemDB_dir + "/S5.4.0.GTDB_r226.metapackage_20250331.smpkg.zb")
    conda: 
        workflow.basedir + '/Workflow/envs/singlem.yaml'
    resources:
        mem_mb = 4000,
        time = 480
    threads: 1
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
    params:
        db_dir = singlemDB_dir
    threads: 8
    resources:
        mem_mb = 38000,
        time = 480
    log:
        log_dir + "/singlem/{sample}_profile.log"
    shell:
        """
        singlem pipe \
            --metapackage "{input.db}" \
            -1 {input.r1} -2 {input.r2} \
            --threads 8 \
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
    threads: 8
    resources:
        mem_mb = 38000,
        time = 480
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
