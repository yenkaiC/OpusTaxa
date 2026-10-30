## Prodigal-GV - Gene prediction for prokaryotes and viruses (including giant viruses)
## Runs on contigs from MetaSPAdes (requires metaspades)

## Run prodigal-gv on assembled contigs
rule prodigal_gv:
    input:
        scaffold = metaspades_dir + "/{sample}/scaffolds.fasta"
    output:
        proteins = prodigalgv_dir + "/{sample}/{sample}_proteins.faa",
        genes    = prodigalgv_dir + "/{sample}/{sample}_genes.fna",
        gff      = prodigalgv_dir + "/{sample}/{sample}_genes.gff"
    conda:
        workflow.basedir + "/Workflow/envs/prodigal-gv.yaml"
    container:
        get_container("prodigal_gv")
    threads: get_threads("prodigal_gv")
    resources:
        mem_mb = get_mem("prodigal_gv"),
        runtime = 800
    log:
        log_dir + "/prodigal_gv/{sample}.log"
    shell:
        """
        source {GUARDS} {SKIP_dir}
        
        mkdir -p {prodigalgv_dir}/{wildcards.sample}

        # prodigal-gv aborts on a FASTA with no records
        if ! fasta_has_records {input.scaffold}; then
            skip_note prodigal_gv {wildcards.sample} "no contigs assembled" {log}
            : > {output.proteins}
            : > {output.genes}
            echo "##gff-version 3" > {output.gff}
            exit 0
        fi

        prodigal-gv \
            -i {input.scaffold} \
            -a {output.proteins} \
            -d {output.genes} \
            -o {output.gff} \
            -f gff \
            -p meta \
            -q 2> {log}
        """

## Summarise gene prediction stats across all samples
rule prodigal_gv_summary:
    input:
        gff_files = expand(prodigalgv_dir + "/{sample}/{sample}_genes.gff", sample=SAMPLES)
    output:
        summary = prodigalgv_dir + "/table/prodigal_gv_summary.tsv"
    log:
        log_dir + "/prodigal_gv/summary.log"
    resources:
        mem_mb = get_mem("prodigal_gv_summary"),
        runtime = 30
    threads: 2
    shell:
        """
        mkdir -p $(dirname {output.summary})

        # Header
        echo -e "sample\\ttotal_genes\\tcomplete_genes\\tpartial_genes\\tavg_gene_length" > {output.summary}

        for gff in {input.gff_files}; do
            sample=$(basename $(dirname "$gff"))

            total=$(grep -c "^[^#]" "$gff" 2>/dev/null) || total=0
            complete=$(grep -c "partial=00" "$gff" 2>/dev/null) || complete=0
            partial=$(( total - complete ))

            # Average gene length from start/end coordinates
            avg_len=$(awk -F'\\t' '/^[^#]/ {{len += ($5 - $4 + 1); n++}} END {{if(n>0) printf "%.0f", len/n; else print 0}}' "$gff")

            echo -e "${{sample}}\\t${{total}}\\t${{complete}}\\t${{partial}}\\t${{avg_len}}" >> {output.summary}
        done

        echo "Summarised $(echo {input.gff_files} | wc -w) samples" > {log}
        """

## Per-gene table across all samples (one row per predicted gene)
rule prodigal_gv_gene_table:
    input:
        gff_files = expand(prodigalgv_dir + "/{sample}/{sample}_genes.gff", sample=SAMPLES)
    output:
        genes = prodigalgv_dir + "/table/prodigal_gv_genes.tsv.gz"
    params:
        prodigal_dir = prodigalgv_dir,
        samples = SAMPLES
    log:
        log_dir + "/prodigal_gv/gene_table.log"
    resources:
        mem_mb = get_mem("prodigal_gv_gene_table"),
        runtime = 120
    threads: 1
    script:
        workflow.basedir + "/Workflow/scripts/prodigal_gv_gene_table.py"