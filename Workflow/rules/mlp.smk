## Microbial Load Predictor

rule mlp:
    input:
        profile = metaphlan_dir + "/{sample}_profile.txt"
    output:
        load = mlp_dir + "/{sample}_load.tsv",
        qmp  = mlp_dir + "/{sample}_qmp.tsv"
    conda:
        workflow.basedir + "/Workflow/envs/mlp.yaml"
    log:
        log_dir + "/mlp/{sample}.log"
    resources:
        mem_mb = 8000,
        time = 60
    threads: 1
    script:
        workflow.basedir + "/Workflow/scripts/mlp.R"