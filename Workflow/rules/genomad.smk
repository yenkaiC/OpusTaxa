## geNomad - Identification of plasmids and viruses from assembled contigs
## Requires MetaSPAdes assembly (metaspades=true)
## Classifies contigs as chromosomal, plasmid, or viral using a hybrid
## marker-based + neural network approach

## Download geNomad database
rule dl_genomad_db:
    output:
        checkpoint = DB_dir + "/genomad/.download_complete"
    conda:
        "../envs/genomad.yaml"
    container:
        get_container("genomad")
    params:
        db_dir = DB_dir + "/genomad"
    resources:
        mem_mb = 16000,
        runtime = 480
    threads: 2
    log:
        log_dir + "/genomad/database_dl.log"
    shell:
        """
        mkdir -p {params.db_dir}
        if [ ! -d "{params.db_dir}/genomad_db" ]; then
            genomad download-database {params.db_dir} 2> {log}
        else
            echo "geNomad database already exists, skipping download" > {log}
        fi
        touch {output.checkpoint}
        """

## Run geNomad end-to-end on assembled contigs
rule genomad:
    input:
        contigs  = metaspades_dir + "/{sample}/contigs.fasta",
        db       = DB_dir + "/genomad/.download_complete"
    output:
        plasmid_summary  = genomad_dir + "/{sample}/contigs_summary/{sample}_plasmid_summary.tsv",
        virus_summary    = genomad_dir + "/{sample}/contigs_summary/{sample}_virus_summary.tsv",
        plasmid_fna      = genomad_dir + "/{sample}/contigs_summary/{sample}_plasmids.fna",
        virus_fna        = genomad_dir + "/{sample}/contigs_summary/{sample}_viruses.fna",
        plasmid_genes    = genomad_dir + "/{sample}/contigs_summary/{sample}_plasmids_genes.tsv",
        virus_genes      = genomad_dir + "/{sample}/contigs_summary/{sample}_viruses_genes.tsv",
        complete         = touch(genomad_dir + "/{sample}/.genomad_complete")
    conda:
        "../envs/genomad.yaml"
    container:
        get_container("genomad")
    params:
        db_dir  = DB_dir + "/genomad/genomad_db",
        out_dir = genomad_dir + "/{sample}",
        splits  = get_param("genomad", "splits", 8),
        min_score   = get_param("genomad", "min_score", 0.7),
        min_seq_size = get_param("genomad", "min_seq_size", 1000)
    threads: get_threads("genomad")
    resources:
        mem_mb  = 32000,
        runtime = 720
    log:
        log_dir + "/genomad/{sample}.log"
    shell:
        """
        mkdir -p {params.out_dir}

        # Rename outputs to include sample name (geNomad uses input filename as prefix)
        genomad end-to-end \
            --cleanup \
            --splits {params.splits} \
            --min-score {params.min_score} \
            --min-seq-size {params.min_seq_size} \
            --threads {threads} \
            {input.contigs} \
            {params.out_dir} \
            {params.db_dir} 2> {log}

        # Rename outputs from contigs_* to <sample>_* for clarity
        SAMPLE="{wildcards.sample}"
        cd {params.out_dir}/contigs_summary
        for f in contigs_*; do
            mv "$f" "${{SAMPLE}}_${{f#contigs_}}" 2>> {log} || true
        done
        """

## Merge geNomad plasmid and virus summaries across all samples
rule genomad_summary_table:
    input:
        complete = expand(genomad_dir + "/{sample}/.genomad_complete", sample=SAMPLES)
    output:
        plasmid_merged = genomad_dir + "/table/genomad_plasmid_summary.tsv",
        virus_merged   = genomad_dir + "/table/genomad_virus_summary.tsv"
    params:
        genomad_dir = genomad_dir,
        samples     = " ".join(SAMPLES)
    log:
        log_dir + "/genomad/summary_table.log"
    resources:
        mem_mb  = 20000,
        runtime = 45
    threads: 2
    shell:
        """
        mkdir -p {params.genomad_dir}/table

        for element_type in plasmid virus; do

            if [ "$element_type" = "plasmid" ]; then
                outfile="{output.plasmid_merged}"
            else
                outfile="{output.virus_merged}"
            fi

            header_written=0
            > "$outfile"

            for sample in {params.samples}; do
                tsv="{params.genomad_dir}/${{sample}}/contigs_summary/${{sample}}_${{element_type}}_summary.tsv"

                if [ ! -f "$tsv" ]; then
                    echo "WARNING: $tsv not found, skipping" >> {log}
                    continue
                fi

                if [ "$header_written" -eq 0 ]; then
                    # Print header with sample column prepended
                    head -1 "$tsv" | awk '{{print "sample\t" $0}}' >> "$outfile"
                    header_written=1
                fi

                # Print data rows with sample name prepended, skipping header
                tail -n +2 "$tsv" | awk -v s="$sample" '{{print s"\t"$0}}' >> "$outfile"
            done

        done

        echo "Merged geNomad summaries for $(echo {params.samples} | wc -w) samples" > {log}
        """