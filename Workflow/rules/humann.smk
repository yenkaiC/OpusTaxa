## Download HUMAnN databases
# The huttenhower.sph.harvard.edu server redirects to Globus, which may be blocked on some HPCs.
# Each rule tries humann_databases first, then falls back to direct Globus wget.
# If both fail, the rule exits with a clear error and manual instructions.
# Manual download instructions (run on a machine with internet access, then transfer to HPC):
#   wget https://g-227ca.190ebd.75bc.data.globus.org/humann_data/chocophlan/full_chocophlan.v201901_v31.tar.gz
#   wget https://g-227ca.190ebd.75bc.data.globus.org/humann_data/uniprot/uniref_annotated/uniref90_annotated_v201901b_full.tar.gz
#   wget https://g-227ca.190ebd.75bc.data.globus.org/humann_data/full_mapping_v201901b.tar.gz

rule dl_humann_chocophlan:
    output:
        checkpoint = humannDB_dir + "/.chocophlan_download_complete"
    conda:
        workflow.basedir + '/Workflow/envs/humann.yaml'
    container:
        get_container("humann")
    params:
        db_dir      = humannDB_dir + "/chocophlan",
        globus_url  = "https://g-227ca.190ebd.75bc.data.globus.org/humann_data/chocophlan/full_chocophlan.v201901_v31.tar.gz"
    resources:
        mem_mb = 20000,
        runtime = 480
    threads: 2
    log:
        log_dir + "/humann/chocophlan_dl.log"
    shell:
        """
        mkdir -p {params.db_dir}
        if [ ! "$(ls -A {params.db_dir})" ]; then
            echo "Attempting humann_databases download..." > {log}
            if humann_databases --download chocophlan full {params.db_dir} 2>> {log}; then
                echo "humann_databases download succeeded" >> {log}
            else
                echo "humann_databases failed, trying direct Globus wget..." >> {log}
                if wget -q -O {params.db_dir}/chocophlan.tar.gz {params.globus_url} 2>> {log}; then
                    tar -xzf {params.db_dir}/chocophlan.tar.gz -C {params.db_dir} 2>> {log}
                    rm {params.db_dir}/chocophlan.tar.gz
                    humann_config --update database_folders nucleotide {params.db_dir} 2>> {log}
                    echo "Globus download succeeded" >> {log}
                else
                    echo "ERROR: Both download methods failed for ChocoPhlAn." >> {log}
                    echo "Please download manually and place files in {params.db_dir}:" >> {log}
                    echo "  wget {params.globus_url}" >> {log}
                    echo "  tar -xzf full_chocophlan.v201901_v31.tar.gz -C {params.db_dir}" >> {log}
                    exit 1
                fi
            fi
        else
            echo "ChocoPhlAn database already exists, skipping download" > {log}
        fi
        touch {output.checkpoint}
        """

rule dl_humann_uniref:
    output:
        checkpoint = humannDB_dir + "/.uniref_download_complete"
    conda:
        workflow.basedir + '/Workflow/envs/humann.yaml'
    container:
        get_container("humann")
    params:
        db_dir      = humannDB_dir + "/uniref",
        globus_url  = "https://g-227ca.190ebd.75bc.data.globus.org/humann_data/uniprot/uniref_annotated/uniref90_annotated_v201901b_full.tar.gz"
    resources:
        mem_mb = 20000,
        runtime = 480
    threads: 2
    log:
        log_dir + "/humann/uniref_dl.log"
    shell:
        """
        mkdir -p {params.db_dir}
        if [ ! "$(ls -A {params.db_dir})" ]; then
            echo "Attempting humann_databases download..." > {log}
            if humann_databases --download uniref uniref90_diamond {params.db_dir} 2>> {log}; then
                echo "humann_databases download succeeded" >> {log}
            else
                echo "humann_databases failed, trying direct Globus wget..." >> {log}
                if wget -q -O {params.db_dir}/uniref.tar.gz {params.globus_url} 2>> {log}; then
                    tar -xzf {params.db_dir}/uniref.tar.gz -C {params.db_dir} 2>> {log}
                    rm {params.db_dir}/uniref.tar.gz
                    humann_config --update database_folders protein {params.db_dir} 2>> {log}
                    echo "Globus download succeeded" >> {log}
                else
                    echo "ERROR: Both download methods failed for UniRef90." >> {log}
                    echo "Please download manually and place files in {params.db_dir}:" >> {log}
                    echo "  wget {params.globus_url}" >> {log}
                    echo "  tar -xzf uniref90_annotated_v201901b_full.tar.gz -C {params.db_dir}" >> {log}
                    exit 1
                fi
            fi
        else
            echo "UniRef database already exists, skipping download" > {log}
        fi
        touch {output.checkpoint}
        """

rule dl_humann_utility:
    output:
        checkpoint = humannDB_dir + "/.utility_mapping_download_complete"
    conda:
        workflow.basedir + '/Workflow/envs/humann.yaml'
    container:
        get_container("humann")
    params:
        db_dir      = humannDB_dir + "/utility_mapping",
        globus_url  = "https://g-227ca.190ebd.75bc.data.globus.org/humann_data/full_mapping_v201901b.tar.gz"
    resources:
        mem_mb = 6000,
        runtime = 240
    threads: 2
    log:
        log_dir + "/humann/utility_dl.log"
    shell:
        """
        mkdir -p {params.db_dir}
        if [ ! "$(ls -A {params.db_dir})" ]; then
            echo "Attempting humann_databases download..." > {log}
            if humann_databases --download utility_mapping full {params.db_dir} 2>> {log}; then
                echo "humann_databases download succeeded" >> {log}
            else
                echo "humann_databases failed, trying direct Globus wget..." >> {log}
                if wget -q -O {params.db_dir}/utility.tar.gz {params.globus_url} 2>> {log}; then
                    tar -xzf {params.db_dir}/utility.tar.gz -C {params.db_dir} 2>> {log}
                    rm {params.db_dir}/utility.tar.gz
                    humann_config --update database_folders utility_mapping {params.db_dir} 2>> {log}
                    echo "Globus download succeeded" >> {log}
                else
                    echo "ERROR: Both download methods failed for utility_mapping." >> {log}
                    echo "Please download manually and place files in {params.db_dir}:" >> {log}
                    echo "  wget {params.globus_url}" >> {log}
                    echo "  tar -xzf full_mapping_v201901b.tar.gz -C {params.db_dir}" >> {log}
                    exit 1
                fi
            fi
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
        chocophlan   = humannDB_dir + "/.chocophlan_download_complete",
        uniref       = humannDB_dir + "/.uniref_download_complete",
        utility      = humannDB_dir + "/.utility_mapping_download_complete"
    output:
        genefamilies  = humann_dir + "/genefamilies/{sample}_genefamilies.tsv",
        pathabundance = humann_dir + "/pathabundance/{sample}_pathabundance.tsv",
        pathcoverage  = humann_dir + "/pathcoverage/{sample}_pathcoverage.tsv"
    conda:
        workflow.basedir + "/Workflow/envs/humann.yaml"
    container:
        get_container("humann")
    params:
        outdir  = humann_dir + "/temp/{sample}",
        protdb  = humannDB_dir + "/uniref",
        gf_dir  = humann_dir + "/genefamilies",
        pa_dir  = humann_dir + "/pathabundance",
        pc_dir  = humann_dir + "/pathcoverage"
    threads: get_threads("humann")
    resources:
        mem_mb = 64000,
        runtime = 1400
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
    container:
        get_container("humann")
    params:
        gf_dir = humann_dir + "/genefamilies",
        pa_dir = humann_dir + "/pathabundance",
        pc_dir = humann_dir + "/pathcoverage",
        merge_dir = humann_dir + "/merged"
    resources:
        mem_mb = 32000,
        runtime = 360
    log:
        log_dir + "/humann/merge_tables.log"
    shell:
        """
        mkdir -p {params.merge_dir}

        # Join tables
        humann_join_tables -i {params.gf_dir} -o {params.merge_dir}/genefamilies_joined.tsv --file_name genefamilies 2> {log} 
        humann_join_tables -i {params.pa_dir} -o {params.merge_dir}/pathabundance_joined.tsv --file_name pathabundance 2>> {log} 
        humann_join_tables -i {params.pc_dir} -o {params.merge_dir}/pathcoverage_joined.tsv --file_name pathcoverage 2>> {log} 

        # Normalize to CPM
        humann_renorm_table -i {params.merge_dir}/genefamilies_joined.tsv -o {params.merge_dir}/genefamilies_cpm.tsv --units cpm 2>> {log} 
        humann_renorm_table -i {params.merge_dir}/pathabundance_joined.tsv -o {params.merge_dir}/pathabundance_cpm.tsv --units cpm 2>> {log}

        # Split stratified tables
        humann_split_stratified_table -i {params.merge_dir}/genefamilies_cpm.tsv -o {params.merge_dir} 2>> {log} 
        humann_split_stratified_table -i {params.merge_dir}/pathabundance_cpm.tsv -o {params.merge_dir} 2>> {log} 
        humann_split_stratified_table -i {params.merge_dir}/pathcoverage_joined.tsv -o {params.merge_dir} 2>> {log}
        """