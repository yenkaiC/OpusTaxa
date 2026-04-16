
# preflight
"""
Database location
"""
if not config["hecatomb"]["args"]["databases"]:
    try:
        assert(os.environ["HECATOMB_DB"]) is not None
        config["hecatomb"]["args"]["databases"] = os.environ["HECATOMB_DB"]
    except (KeyError, AssertionError):
        config["hecatomb"]["args"]["databases"] = DB_dir


"""
Expand output, temp, database dir and file paths to include base directories
"""
for db_file_path in config["hecatomb"]["args"]["database_paths"]:
    config["hecatomb"]["args"]["database_paths"][db_file_path] =  os.path.join(
        config["hecatomb"]["args"]["databases"], config["hecatomb"]["args"]["database_paths"][db_file_path]
    )


"""
Testing databases
"""
# if config["hecatomb"]["args"]["testing"]:
#     config["hecatomb"]["args"]["database_paths"]["primaryAA"] += "_testing"
#     config["hecatomb"]["args"]["database_paths"]["secondaryAA"] += "_testing"
#     config["hecatomb"]["args"]["database_paths"]["primaryNT"] += "_testing"
#     config["hecatomb"]["args"]["database_paths"]["secondaryNT"] += "_testing"



# DOWNLOAD RULES
rule download_db_file:
    """Download a Hecatomb-maintained DB file."""
    output:
        os.path.join(config["hecatomb"]["args"]["databases"], "{path}","{file}")
    wildcard_constraints:
        path=r"aa/virus_.*_aa|nt/virus_.*_nt|host|contaminants|tables"
    run:
        import urllib.request
        import urllib.parse
        import shutil
        dlUrl1 = urllib.parse.urljoin(config["hecatomb"]["dbs"]["mirror1"], os.path.join(wildcards.path, wildcards.file))
        dlUrl2 = urllib.parse.urljoin(config["hecatomb"]["dbs"]["mirror2"], os.path.join(wildcards.path, wildcards.file))
        try:
            with urllib.request.urlopen(dlUrl1) as r, open(output[0],'wb') as o:
                shutil.copyfileobj(r,o)
        except:
            with urllib.request.urlopen(dlUrl2) as r, open(output[0],'wb') as o:
                shutil.copyfileobj(r,o)


# rule unzip_test_db:
#     """Unzip Hecatomb test DB files"""
#     input:
#         os.path.join(os.path.join(workflow.basedir, "..", "hecatomb-testdb"), "{path}","{file}.zst")
#     output:
#         os.path.join(config["hecatomb"]["args"]["databases"], "{path}","{file}")
#     wildcard_constraints:
#         path=r"../virus_.*_testing",
#         file=r"(?!.*zst$).*"
#     conda:
#         os.path.join("..", "..", "envs", "krona_curl_zstd_pysam.yaml")
#     container:
#         config["hecatomb"]["container"]["krona_curl_zstd_pysam"]
#     shell:
#         """
#         zstd -d {input} -o {output}
#         """


rule download_taxdump:
    """Download the current NCBI taxdump."""
    output:
        expand(os.path.join(config["hecatomb"]["args"]["databases"], "{file}"), file=config["hecatomb"]["dbtax"]["files"]),
        temp(config["hecatomb"]["dbtax"]["tar"])
    params:
        url = config["hecatomb"]["dbtax"]["url"],
        tar = config["hecatomb"]["dbtax"]["tar"],
        md5 = config["hecatomb"]["dbtax"]["md5"],
        dir = os.path.join(config["hecatomb"]["args"]["databases"], "taxonomy")
    conda:
        os.path.join("..", "envs", "krona_curl_zstd_pysam.yaml")
    container:
        config["hecatomb"]["container"]["krona_curl_zstd_pysam"]
    shell:
        """
        curl {params.url} -o {params.tar}
        curl {params.md5} | md5sum -c
        mkdir -p {params.dir}
        tar xvf {params.tar} -C {params.dir}
        """




# rules

rule contig_annotation_mmseqs_search:
    """Contig annotation step 01: Assign taxonomy to contigs in contig_dictionary using mmseqs

    Database: NCBI virus assembly with taxID added
    """
    input:
        contigs=os.path.join(metaspades_dir, "{sample}","scaffolds.fasta"),
        db=expand(os.path.join(config["hecatomb"]["args"]["database_paths"]["secondaryNT"],"{file}"),
            file=["sequenceDB","sequenceDB.dbtype","sequenceDB_h","sequenceDB_h.dbtype","sequenceDB_h.index", "sequenceDB.index", "sequenceDB.lookup", "sequenceDB.source"
        ]),
    output:
        queryDB=os.path.join(hecatomb_dir,"{sample}","queryDB"),
        result=os.path.join(hecatomb_dir,"{sample}","result", "result.index")
    params:
        db = os.path.join(config["hecatomb"]["args"]["database_paths"]["secondaryNT"],"sequenceDB"),
        resdir=os.path.join(hecatomb_dir,"{sample}","result"),
        prefix=os.path.join(hecatomb_dir,"{sample}","result","result"),
        tmppath=os.path.join(hecatomb_dir,"{sample}","tmp"),
        sensnt=config["hecatomb"]["mmseqs"][config["hecatomb"]["args"]["search"]],
        memsplit=str(int(0.75 * int(config["resources"]["big"]["mem_mb"]))) + "M",
        filtnt=config["hecatomb"]["mmseqs"]["filtNT"]
    benchmark:
        os.path.join(log_dir,"mmseqs_contig_annotation.{sample}.bench")
    log:
        os.path.join(log_dir,"mmseqs_contig_annotation.{sample}.log")
    resources:
        **config["resources"]["big"]
    threads:
        config["resources"]["big"]["cpu"]
    conda:
        os.path.join("..","envs","mmseqs2_seqkit_taxonkit_csvtk.yaml")
    container:
        config["hecatomb"]["container"]["mmseqs2_seqkit_taxonkit_csvtk"]
    # group:
    #     "contigannot"
    shell:
        "{{ if [[ -d {params.resdir} ]]; then rm -r {params.resdir}; fi; "
        "if [[ -d {params.tmppath} ]]; then rm -r {params.tmppath}; fi; "
        "mkdir -p {params.resdir}; "
        "mmseqs createdb {input.contigs} {output.queryDB} --dbtype 2; "
        "mmseqs search {output.queryDB} {params.db} {params.prefix} {params.tmppath} "
        "{params.sensnt} --split-memory-limit {params.memsplit} {params.filtnt} "
        "--search-type 3 --threads {threads} ; }} &> {log}"


rule contig_annotation_mmseqs_summary:
    """Contig annotation step 02: Summarize mmseqs contig annotation results"""
    input:
        queryDB=os.path.join(hecatomb_dir,"{sample}","queryDB"),
        db=expand(os.path.join(config["hecatomb"]["args"]["database_paths"]["secondaryNT"],"{file}"),
            file=["sequenceDB","sequenceDB.dbtype","sequenceDB_h","sequenceDB_h.dbtype","sequenceDB_h.index", "sequenceDB.index", "sequenceDB.lookup", "sequenceDB.source"
        ]),
        taxdb=expand(os.path.join(config["hecatomb"]["args"]["databases"], "{file}"), file=config["hecatomb"]["dbtax"]["files"]),
    output:
        result=os.path.join(hecatomb_dir,"{sample}","result","tophit.index"),
        align=os.path.join(hecatomb_dir,"{sample}","result","tophit.m8"),
        tsv=os.path.join(hecatomb_dir, "{sample}.hecatomb.tsv")
    params:
        db = os.path.join(config["hecatomb"]["args"]["database_paths"]["secondaryNT"],"sequenceDB"),
        inputpath=os.path.join(hecatomb_dir,"{sample}","result"),
        respath=os.path.join(hecatomb_dir,"{sample}","result","tophit"),
        header=config["hecatomb"]["immutable"]["contigAnnotHeader"],
        secondaryNtFormat=config["hecatomb"]["immutable"]["secondaryNtFormat"],
        taxdump = os.path.join(config["hecatomb"]["args"]["database_paths"]["taxonomy"])
    benchmark:
        os.path.join(log_dir,"mmseqs_contig_annotation_summary.{sample}.bench")
    log:
        os.path.join(log_dir,"mmseqs_contig_annotation_summary.{sample}.log")
    resources:
        **config["resources"]["big"]
    threads:
        config["resources"]["big"]["cpu"]
    conda:
        os.path.join("..","envs","mmseqs2_seqkit_taxonkit_csvtk.yaml")
    container:
        config["hecatomb"]["container"]["mmseqs2_seqkit_taxonkit_csvtk"]
    # group:
    #     "contigannot"
    shell:
        "{{ "
            "mmseqs filterdb {params.inputpath} {params.respath} --extract-lines 1; "
            "mmseqs convertalis {input.queryDB} {params.db} {params.respath} {output.align} {params.secondaryNtFormat}; "
            "printf '{params.header}\n' > {output.tsv}; "
            "sed 's/tid|//' {output.align} | "
                r"sed 's/|/\t/' | "
                "taxonkit lineage --data-dir {params.taxdump} -i 2 | "
                "taxonkit reformat2 --data-dir {params.taxdump} -I 19 --miss-rank-repl NA "
                    r"-f '{{domain|acellular root|superkingdom}}\t{{phylum}}\t{{class}}\t{{order}}\t{{family}}\t{{genus}}\t{{species}}' | "
                "cut --complement -f2,19 >> {output.tsv}; "
        "}} &> {log}; "
