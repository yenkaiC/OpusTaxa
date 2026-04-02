## StrainPhlAn - Strain-level metagenomic profiling
## Reconstructs strain phylogenies from MetaPhlAn bowtie2 alignments
## Required for engraftment analysis (e.g. FMT donor → recipient tracking)

## Step 1: Extract consensus marker sequences from each sample's bowtie2 alignment
rule strainphlan_sample2markers:
    input:
        bowtie = metaphlan_dir + "/{sample}_bowtie.bz2",
        db     = metaphlanDB_dir + "/.download_complete"
    output:
        markers = directory(strainphlan_dir + "/consensus_markers/{sample}/")
    conda:
        workflow.basedir + "/Workflow/envs/metaphlan.yaml"
    container:
        get_container("metaphlan")
    params:
        db_dir = metaphlanDB_dir
    threads: get_threads("metaphlan")
    resources:
        mem_mb = 16000,
        runtime = 240
    log:
        log_dir + "/strainphlan/{sample}_sample2markers.log"
    shell:
        """
        mkdir -p {output.markers}
        sample2markers.py \
            -i {input.bowtie} \
            -o {output.markers} \
            -d {params.db_dir} \
            -n {threads} 2> {log}
        """

## Step 2: Extract the reference marker sequences for each species of interest
## Species must be specified in config as a list, e.g.:
##   strainphlan_species:
##     - "t__SGB1877"   # Bacteroides fragilis
##     - "t__SGB6080"   # Faecalibacterium prausnitzii
## Find SGB IDs from your MetaPhlAn profile (t__ level) or the MetaPhlAn database
rule strainphlan_extract_markers:
    input:
        db = metaphlanDB_dir + "/.download_complete"
    output:
        markers = strainphlan_dir + "/db_markers/{species}.fna"
    conda:
        workflow.basedir + "/Workflow/envs/metaphlan.yaml"
    container:
        get_container("metaphlan")
    params:
        db_dir     = metaphlanDB_dir,
        out_dir    = strainphlan_dir + "/db_markers"
    threads: 1
    resources:
        mem_mb = 8000,
        runtime = 60
    log:
        log_dir + "/strainphlan/extract_markers_{species}.log"
    shell:
        """
        mkdir -p {params.out_dir}
        extract_markers.py \
            -c {wildcards.species} \
            -o {params.out_dir} \
            -d {params.db_dir} 2> {log}
        """

## Step 3: Run StrainPhlAn to build a strain phylogeny for each species
rule strainphlan:
    input:
        sample_markers = expand(
            strainphlan_dir + "/consensus_markers/{sample}/",
            sample=SAMPLES
        ),
        db_markers = strainphlan_dir + "/db_markers/{species}.fna",
        db         = metaphlanDB_dir + "/.download_complete"
    output:
        tree = strainphlan_dir + "/output/{species}/RAxML_bestTree.{species}.StrainPhlAn4.tre"
    conda:
        workflow.basedir + "/Workflow/envs/metaphlan.yaml"
    container:
        get_container("metaphlan")
    params:
        db_dir     = metaphlanDB_dir,
        marker_dir = strainphlan_dir + "/consensus_markers",
        out_dir    = strainphlan_dir + "/output/{species}"
    threads: get_threads("metaphlan")
    resources:
        mem_mb = 32000,
        runtime = 480
    log:
        log_dir + "/strainphlan/{species}.log"
    shell:
        """
        mkdir -p {params.out_dir}

        # Collect all per-sample marker pkl files for this species
        MARKER_FILES=$(find {params.marker_dir} -name "{wildcards.species}.pkl" 2>/dev/null | tr '\\n' ' ')

        if [ -z "$MARKER_FILES" ]; then
            echo "ERROR: No marker files found for {wildcards.species}" > {log}
            exit 1
        fi

        strainphlan \
            -s $MARKER_FILES \
            -m {input.db_markers} \
            -d {params.db_dir} \
            -o {params.out_dir} \
            -c {wildcards.species} \
            -n {threads} \
            --phylophlan_mode accurate 2> {log}
        """

### Example of running it ###
## First, find which species/SGBs are detectable across your samples
#grep "t__" Data/MetaPhlAn/sample1_profile.txt | head -20
#
## Then run
#snakemake --use-conda --cores 16 \
#    --config strainphlan=true \
#    strainphlan_species='["t__SGB1877","t__SGB6080"]'
#
## Find t__ (SGB) level entries present in the merged table
#grep "t__" Data/MetaPhlAn/table/abundance_all.txt | \
#    awk -F'\t' '{
#        present=0; 
#        for(i=2;i<=NF;i++) if($i>0) present++; 
#        if(present>=4) print present, $0
#    }' | sort -rn | head -20