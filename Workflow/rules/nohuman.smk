## Download nohuman's Database. 
rule dl_noHuman_DB:
    output:
        nohumanDB_dir + "/taxo.k2d",
        nohumanDB_dir + "/hash.k2d",
        nohumanDB_dir + "/opts.k2d"
    conda: 
        '../envs/nohuman.yaml'
    params:
        nohumanDB_dir
    resources:
        mem_mb = 4000,
        time = 480
    threads: 1
    shell:
        "nohuman --download --db {params}"
        #""" # before update
        #mkdir -p {params}
        #curl -L https://ndownloader.figshare.com/files/59658306 -o {params}/nohuman_db.tar.gz
        #tar -xzvf {params}/nohuman_db.tar.gz -C {params}
        #rm {params}/nohuman_db.tar.gz
        #"""

## Run nohuman
rule remove_human_reads:
    input:
        r1 = clean_dir + "/{sample}_R1_001.fastq.gz",
        r2 = clean_dir + "/{sample}_R2_001.fastq.gz",
        db_taxo = nohumanDB_dir + "/taxo.k2d",
        db_hash = nohumanDB_dir + "/hash.k2d",
        db_opts = nohumanDB_dir + "/opts.k2d"
    output:
        r1 = nohuman_dir + "/{sample}_R1_001.fastq.gz",
        r2 = nohuman_dir + "/{sample}_R2_001.fastq.gz"
    conda: 
        '../envs/nohuman.yaml'
    params:
        db_dir = nohumanDB_dir
    resources:
        mem_mb = 32000, #32GB
        time = 480
    shell:
        "nohuman --db {params.db_dir} -t 8 --out1 {output.r1} --out2 {output.r2} {input.r1} {input.r2}"
