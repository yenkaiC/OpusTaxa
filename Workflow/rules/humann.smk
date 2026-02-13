## Download HUMAnN databases using checkpoint files
rule dl_humann_chocophlan:
    output:
        checkpoint = humannDB_dir + "/chocophlan/.download_complete"
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
        """
        if [ ! -d "{params.db_dir}/chocophlan" ]; then
            humann_databases --download chocophlan full {params.db_dir} 2> {log}
        else
            echo "ChocoPhlAn database already exists, skipping download" > {log}
        fi
        touch {output.checkpoint}
        """

rule dl_humann_uniref:
    output:
        checkpoint = humannDB_dir + "/uniref/.download_complete"
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
        """
        if [ ! -d "{params.db_dir}/uniref" ]; then
            humann_databases --download uniref uniref90_diamond {params.db_dir} 2> {log}
        else
            echo "UniRef database already exists, skipping download" > {log}
        fi
        touch {output.checkpoint}
        """

rule dl_humann_utility:
    output:
        checkpoint = humannDB_dir + "/utility_mapping/.download_complete"
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
        """
        if [ ! -d "{params.db_dir}/utility_mapping" ]; then
            humann_databases --download utility_mapping full {params.db_dir} 2> {log}
        else
            echo "Utility mapping database already exists, skipping download" > {log}
        fi
        touch {output.checkpoint}
        """

## Run HUMAnN3 on forward reads only - Output to type-specific directories
rule humann:
    input:
        r1           = nohuman_dir + "/{sample}_R1_001.fastq.gz",
        profile      = metaphlan_dir + "/{sample}_profile.txt",
        chocophlan   = humannDB_dir + "/chocophlan/.download_complete",
        uniref       = humannDB_dir + "/uniref/.download_complete",
        utility      = humannDB_dir + "/utility_mapping/.download_complete"
    output:
        genefamilies  = humann_dir + "/genefamilies/{sample}_genefamilies.tsv",
        pathabundance = humann_dir + "/pathabundance/{sample}_pathabundance.tsv",
        pathcoverage  = humann_dir + "/pathcoverage/{sample}_pathcoverage.tsv"
    conda:
        workflow.basedir + "/Workflow/envs/humann.yaml"
    params:
        outdir  = humann_dir + "/temp/{sample}",
        protdb  = humannDB_dir + "/uniref/uniref",
        gf_dir  = humann_dir + "/genefamilies",
        pa_dir  = humann_dir + "/pathabundance",
        pc_dir  = humann_dir + "/pathcoverage"
    threads: 8
    resources:
        mem_mb = 64000,
        time = 1440
    log:
        log_dir + "/humann/{sample}.log"
    shell:
        """
        # Create output directories
        mkdir -p {params.outdir} {params.gf_dir} {params.pa_dir} {params.pc_dir}
        
        # Run HUMAnN
        humann \
            --input {input.r1} \
            --output {params.outdir} \
            --taxonomic-profile {input.profile} \
            --bypass-nucleotide-search \
            --protein-database {params.protdb} \
            --threads {threads} \
            --memory-use maximum 2> {log}
        
        # Move output files to type-specific directories
        mv {params.outdir}/*_genefamilies.tsv {output.genefamilies}
        mv {params.outdir}/*_pathabundance.tsv {output.pathabundance}
        mv {params.outdir}/*_pathcoverage.tsv {output.pathcoverage}
        
        # Clean up temp directory
        rm -rf {params.outdir}
        """

## Merge, normalise, and split stratified tables
rule humann_merge_tables:
    input:
        genefamilies  = expand(humann_dir + "/genefamilies/{sample}_genefamilies.tsv",  sample=SAMPLES),
        pathabundance = expand(humann_dir + "/pathabundance/{sample}_pathabundance.tsv", sample=SAMPLES),
        pathcoverage  = expand(humann_dir + "/pathcoverage/{sample}_pathcoverage.tsv",  sample=SAMPLES)
    output:
        gf_cpm_unstrat = humann_dir + "/merged/genefamilies_cpm_unstratified.tsv",
        pa_cpm_unstrat = humann_dir + "/merged/pathabundance_cpm_unstratified.tsv",
        pc_unstrat     = humann_dir + "/merged/pathcoverage_joined_unstratified.tsv"
    conda:
        workflow.basedir + "/Workflow/envs/humann.yaml"
    params:
        gf_dir = humann_dir + "/genefamilies",
        pa_dir = humann_dir + "/pathabundance",
        pc_dir = humann_dir + "/pathcoverage",
        merge_dir = humann_dir + "/merged"
    resources:
        mem_mb = 8000,
        time = 60
    log:
        log_dir + "/humann/merge_tables.log"
    shell:
        """
        mkdir -p {params.merge_dir}

        # Join tables
        humann_join_tables -i {params.gf_dir} -o {params.merge_dir}/genefamilies_joined.tsv --file_name genefamilies 2> {log} || true
        humann_join_tables -i {params.pa_dir} -o {params.merge_dir}/pathabundance_joined.tsv --file_name pathabundance 2>> {log} || true
        humann_join_tables -i {params.pc_dir} -o {params.merge_dir}/pathcoverage_joined.tsv --file_name pathcoverage 2>> {log} || true

        # Normalize to CPM
        humann_renorm_table -i {params.merge_dir}/genefamilies_joined.tsv -o {params.merge_dir}/genefamilies_cpm.tsv --units cpm 2>> {log} || true
        humann_renorm_table -i {params.merge_dir}/pathabundance_joined.tsv -o {params.merge_dir}/pathabundance_cpm.tsv --units cpm 2>> {log} || true

        # Split stratified tables
        humann_split_stratified_table -i {params.merge_dir}/genefamilies_cpm.tsv -o {params.merge_dir} 2>> {log} || true
        humann_split_stratified_table -i {params.merge_dir}/pathabundance_cpm.tsv -o {params.merge_dir} 2>> {log} || true
        humann_split_stratified_table -i {params.merge_dir}/pathcoverage_joined.tsv -o {params.merge_dir} 2>> {log} || true
        """