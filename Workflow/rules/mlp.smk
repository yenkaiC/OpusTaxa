## Microbial Load Predictor

rule mlp:
    input:
        profile = metaphlan_dir + "/table/abundance_species.txt"
    output:
        load = mlp_dir + "/load.tsv",
        qmp  = mlp_dir + "/qmp.tsv"
    conda:
        workflow.basedir + "/Workflow/envs/mlp.yaml"
    log:
        log_dir + "/mlp/mlp.log"
    resources:
        mem_mb = 8000,
        time = 60
    threads: 1
    script:
        workflow.basedir + "/Workflow/scripts/mlp.R"