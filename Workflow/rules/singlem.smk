# Download SingleM Database
rule dl_singlem_DB:
    params:
        db_dir = singlemDB_dir
    output:
        directory(singlemDB_dir + "/S5.4.0.GTDB_r226.metapackage_20250331.smpkg.zb")
    conda: 
        workflow.basedir + '/Workflow/envs/singlem.yaml'
    resources:
        mem_mb=4000
    threads: 1
    shell:
       "singlem data --output-directory {params.db_dir}"

# Run SingleM
rule singlem:
    input:
        r1 = nohuman_dir + "/{sample}_R1_001.fastq.gz",
        r2 = nohuman_dir + "/{sample}_R2_001.fastq.gz",
        db = singlemDB_dir + "/S5.4.0.GTDB_r226.metapackage_20250331.smpkg.zb"
    output:
        otu_table = singlem_dir + "/{sample}_otu-table.tsv"
    conda:
        workflow.basedir + "/Workflow/envs/singlem.yaml"
    params:
        db_dir = singlemDB_dir
    threads: 8
    shell:
        """
        singlem pipe \
            --metapackage "{input.db}" \
            -1 {input.r1} -2 {input.r2} \
            --otu-table {output.otu_table}
        """
