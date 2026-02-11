## Download HUMAnN databases
rule dl_humann_DB:
    output:
        chocophlan = directory(humannDB_dir + "/chocophlan"),
        uniref      = directory(humannDB_dir + "/uniref")
    conda:
        workflow.basedir + "/Workflow/envs/humann.yaml"
    params:
        db_dir = humannDB_dir
    resources:
        mem_mb = 8000,
        time = 480
    threads: 1
    log:
        log_dir + "/humann/databaseDL.log"
    shell:
        """
        humann_databases --download chocophlan full {params.db_dir} 2> {log}
        humann_databases --download uniref uniref90_diamond {params.db_dir} 2>> {log}
        """