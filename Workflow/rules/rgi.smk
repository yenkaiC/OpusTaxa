## RGI (Resistance Gene Identifier) - CARD Database Integration
## Dual-mode approach: read-based screening + contig-based annotation

## Download CARD Database
rule dl_card_DB:
    output:
        json = DB_dir + "/card/card.json",
        wildcard = DB_dir + "/card/wildcard/index-for-model-sequences.txt"
    conda:
        workflow.basedir + '/Workflow/envs/rgi.yaml'
    params:
        db_dir = DB_dir + "/card"
    resources:
        mem_mb = 4000,
        time = 120
    threads: 1
    log:
        log_dir + "/rgi/card_db_download.log"
    shell:
        """
        # Create log directory first
        mkdir -p $(dirname {log})
        
        # Create database directory
        mkdir -p {params.db_dir}
        
        # Save current directory and log path as absolute paths
        WORKDIR=$(pwd)
        LOGFILE="$WORKDIR/{log}"
        
        cd {params.db_dir}
        
        # Download latest CARD data
        wget -O card-data.tar.bz2 https://card.mcmaster.ca/latest/data 2> "$LOGFILE"
        tar -xvf card-data.tar.bz2 2>> "$LOGFILE"
        
        # Load CARD database into RGI
        rgi load --card_json card.json --local 2>> "$LOGFILE"
        
        # Load wildcard data for read mapping - FIXED COMMAND
        rgi card_annotation -i card.json > card_annotation.log 2>> "$LOGFILE"
        rgi wildcard_annotation -i card.json --card_annotation card_database_v*.fasta --wildcard card_wildcard_v*.fasta 2>> "$LOGFILE"
        
        # Create k-mer database for read-based analysis - FIXED COMMAND
        rgi load -i card.json --card_annotation card_database_v*.fasta --wildcard card_wildcard_v*.fasta --local 2>> "$LOGFILE"
        
        # Build indices for BWA/Bowtie2
        rgi bwt 2>> "$LOGFILE"
        
        # Clean up
        rm card-data.tar.bz2
        
        # Return to original directory
        cd "$WORKDIR"
        """

## MODE 1: Read-based RGI (Fast screening)
## Uses BWA/Bowtie2 alignment for rapid ARG detection
rule rgi_reads:
    input:
        r1 = nohuman_dir + "/{sample}_R1_001.fastq.gz",
        r2 = nohuman_dir + "/{sample}_R2_001.fastq.gz",
        db_json = DB_dir + "/card/card.json",
        db_wildcard = DB_dir + "/card/wildcard/index-for-model-sequences.txt"
    output:
        gene_mapping_data = rgi_dir + "/{sample}/reads/{sample}_sorted.length_100.bam",
        allele_mapping_data = rgi_dir + "/{sample}/reads/{sample}.allele_mapping_data.txt",
        gene_mapping_json = rgi_dir + "/{sample}/reads/{sample}.gene_mapping_data.txt",
        artifacts = rgi_dir + "/{sample}/reads/{sample}.artifacts_mapping_stats.txt",
        overall = rgi_dir + "/{sample}/reads/{sample}.overall_mapping_stats.txt"
    conda:
        workflow.basedir + "/Workflow/envs/rgi.yaml"
    params:
        outdir = rgi_dir + "/{sample}/reads",
        prefix = "{sample}"
    threads: 8
    resources:
        mem_mb = 32000,
        time = 480  # 8 hours
    log:
        log_dir + "/rgi/{sample}_reads.log"
    shell:
        """
        mkdir -p {params.outdir}
        cd {params.outdir}
        
        rgi bwt \
            --read_one {input.r1} \
            --read_two {input.r2} \
            --output_file {params.prefix} \
            --threads {threads} \
            --local \
            --clean 2> {log}
        """

## MODE 2: Contig-based RGI (Detailed annotation)
## Requires metaSPAdes assembly - only runs if metaspades is enabled
rule rgi_contigs:
    input:
        contigs = metaspades_dir + "/{sample}/contigs.fasta",
        db_json = DB_dir + "/card/card.json"
    output:
        txt = rgi_dir + "/{sample}/contigs/{sample}_rgi.txt",
        json = rgi_dir + "/{sample}/contigs/{sample}_rgi.json"
    conda:
        workflow.basedir + "/Workflow/envs/rgi.yaml"
    params:
        outdir = rgi_dir + "/{sample}/contigs",
        prefix = "{sample}_rgi"
    threads: 8
    resources:
        mem_mb = 16000,
        time = 240  # 4 hours
    log:
        log_dir + "/rgi/{sample}_contigs.log"
    shell:
        """
        mkdir -p {params.outdir}
        cd {params.outdir}
        
        rgi main \
            --input_sequence {input.contigs} \
            --output_file {params.prefix} \
            --input_type contig \
            --local \
            --clean \
            --num_threads {threads} \
            --alignment_tool DIAMOND \
            --low_quality 2> {log}
        """

## Generate heatmap visualization for read-based results
rule rgi_reads_heatmap:
    input:
        gene_mapping = expand(rgi_dir + "/{sample}/reads/{sample}.gene_mapping_data.txt", sample=SAMPLES)
    output:
        heatmap = rgi_dir + "/summary/reads_heatmap.png",
        csv = rgi_dir + "/summary/reads_matrix.csv"
    conda:
        workflow.basedir + "/Workflow/envs/rgi.yaml"
    params:
        input_dir = rgi_dir,
        outdir = rgi_dir + "/summary"
    resources:
        mem_mb = 8000,
        time = 60
    log:
        log_dir + "/rgi/reads_heatmap.log"
    shell:
        """
        mkdir -p {params.outdir}
        
        rgi heatmap \
            --input {params.input_dir} \
            --output {params.outdir}/reads_heatmap \
            --category drug_class \
            --frequency \
            --clusterby samples 2> {log}
        
        # Also create by resistance mechanism
        rgi heatmap \
            --input {params.input_dir} \
            --output {params.outdir}/reads_heatmap_mechanism \
            --category resistance_mechanism \
            --frequency \
            --clusterby samples 2>> {log}
        """

## Generate heatmap visualization for contig-based results (if available)
rule rgi_contigs_heatmap:
    input:
        contig_results = expand(rgi_dir + "/{sample}/contigs/{sample}_rgi.txt", sample=SAMPLES)
    output:
        heatmap = rgi_dir + "/summary/contigs_heatmap.png",
        csv = rgi_dir + "/summary/contigs_matrix.csv"
    conda:
        workflow.basedir + "/Workflow/envs/rgi.yaml"
    params:
        input_dir = rgi_dir,
        outdir = rgi_dir + "/summary"
    resources:
        mem_mb = 8000,
        time = 60
    log:
        log_dir + "/rgi/contigs_heatmap.log"
    shell:
        """
        mkdir -p {params.outdir}
        
        rgi heatmap \
            --input {params.input_dir} \
            --output {params.outdir}/contigs_heatmap \
            --category drug_class \
            --clusterby samples 2> {log}
        
        # Also create by gene family
        rgi heatmap \
            --input {params.input_dir} \
            --output {params.outdir}/contigs_heatmap_gene_family \
            --category gene_family \
            --clusterby samples 2>> {log}
        """

## Merge results across all samples for comparative analysis
rule rgi_merge_results:
    input:
        reads = expand(rgi_dir + "/{sample}/reads/{sample}.gene_mapping_data.txt", sample=SAMPLES),
        contigs = expand(rgi_dir + "/{sample}/contigs/{sample}_rgi.txt", sample=SAMPLES) if run_metaspades else []
    output:
        reads_summary = rgi_dir + "/summary/all_samples_reads_summary.txt",
        contigs_summary = rgi_dir + "/summary/all_samples_contigs_summary.txt" if run_metaspades else []
    conda:
        workflow.basedir + "/Workflow/envs/rgi.yaml"
    params:
        reads_dir = rgi_dir,
        summary_dir = rgi_dir + "/summary"
    resources:
        mem_mb = 8000,
        time = 60
    log:
        log_dir + "/rgi/merge_results.log"
    shell:
        """
        mkdir -p {params.summary_dir}
        
        # Merge read-based results
        echo "Sample\tARO_Term\tModel_Type\tResistance_Mechanism\tDrug_Class\tCoverage\tDepth" > {output.reads_summary}
        
        for sample in {SAMPLES}; do
            if [ -f {params.reads_dir}/${{sample}}/reads/${{sample}}.gene_mapping_data.txt ]; then
                tail -n +2 {params.reads_dir}/${{sample}}/reads/${{sample}}.gene_mapping_data.txt | \
                awk -v sample=$sample 'BEGIN{{OFS="\t"}}{{print sample,$0}}' >> {output.reads_summary}
            fi
        done 2> {log}
        
        # Merge contig-based results if metaspades is enabled
        if [ "{run_metaspades}" = "True" ]; then
            echo "Sample\tORF_ID\tContig\tStart\tStop\tStrand\tCut_Off\tARO\tModel_type\tResistance_Mechanism\tDrug_Class\tGene_Family" > {output.contigs_summary}
            
            for sample in {SAMPLES}; do
                if [ -f {params.reads_dir}/${{sample}}/contigs/${{sample}}_rgi.txt ]; then
                    tail -n +2 {params.reads_dir}/${{sample}}/contigs/${{sample}}_rgi.txt | \
                    awk -v sample=$sample 'BEGIN{{OFS="\t"}}{{print sample,$0}}' >> {output.contigs_summary}
                fi
            done 2>> {log}
        fi
        """

## Generate comprehensive RGI report comparing both modes
rule rgi_comparative_report:
    input:
        reads_summary = rgi_dir + "/summary/all_samples_reads_summary.txt",
        contigs_summary = rgi_dir + "/summary/all_samples_contigs_summary.txt" if run_metaspades else [],
        reads_heatmap = rgi_dir + "/summary/reads_heatmap.png"
    output:
        report = rgi_dir + "/summary/RGI_comparative_report.html"
    params:
        summary_dir = rgi_dir + "/summary"
    resources:
        mem_mb = 4000,
        time = 30
    log:
        log_dir + "/rgi/comparative_report.log"
    run:
        import pandas as pd
        from datetime import datetime
        
        # Read data
        reads_df = pd.read_csv(input.reads_summary, sep="\t")
        
        # Start HTML report
        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>OpusTaxa RGI Resistome Analysis Report</title>
            <style>
                body {{ font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }}
                .container {{ max-width: 1200px; margin: auto; background: white; padding: 30px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }}
                h1 {{ color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }}
                h2 {{ color: #34495e; margin-top: 30px; border-left: 4px solid #3498db; padding-left: 10px; }}
                .summary-box {{ background: #ecf0f1; padding: 15px; border-radius: 5px; margin: 15px 0; }}
                table {{ border-collapse: collapse; width: 100%; margin: 15px 0; }}
                th {{ background: #3498db; color: white; padding: 12px; text-align: left; }}
                td {{ padding: 10px; border-bottom: 1px solid #ddd; }}
                tr:hover {{ background: #f9f9f9; }}
                .metric {{ font-size: 24px; font-weight: bold; color: #e74c3c; }}
                img {{ max-width: 100%; height: auto; margin: 20px 0; border: 1px solid #ddd; }}
                .footer {{ margin-top: 40px; padding-top: 20px; border-top: 1px solid #ddd; color: #7f8c8d; font-size: 12px; }}
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🦠 OpusTaxa RGI Resistome Analysis Report</h1>
                <p><strong>Generated:</strong> {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}</p>
                
                <h2>📊 Summary Statistics</h2>
                <div class="summary-box">
                    <p><strong>Total Samples Analyzed:</strong> <span class="metric">{reads_df['Sample'].nunique()}</span></p>
                    <p><strong>Unique ARGs Detected (Read-based):</strong> <span class="metric">{reads_df['ARO_Term'].nunique()}</span></p>
                    <p><strong>Total ARG Observations:</strong> <span class="metric">{len(reads_df)}</span></p>
                </div>
        """
        
        # Drug class summary
        drug_summary = reads_df.groupby('Drug_Class').size().sort_values(ascending=False).head(10)
        html += """
                <h2>💊 Top 10 Drug Classes</h2>
                <table>
                    <tr><th>Drug Class</th><th>Detection Count</th></tr>
        """
        for drug_class, count in drug_summary.items():
            html += f"<tr><td>{drug_class}</td><td>{count}</td></tr>"
        html += "</table>"
        
        # Resistance mechanisms
        mech_summary = reads_df.groupby('Resistance_Mechanism').size().sort_values(ascending=False)
        html += """
                <h2>🔬 Resistance Mechanisms Detected</h2>
                <table>
                    <tr><th>Mechanism</th><th>Detection Count</th></tr>
        """
        for mechanism, count in mech_summary.items():
            html += f"<tr><td>{mechanism}</td><td>{count}</td></tr>"
        html += "</table>"
        
        # Add heatmap
        html += """
                <h2>🔥 ARG Distribution Heatmap (Drug Class)</h2>
                <img src="reads_heatmap.png" alt="ARG Heatmap">
        """
        
        # If contig data exists
        if run_metaspades and input.contigs_summary:
            contigs_df = pd.read_csv(input.contigs_summary, sep="\t")
            html += f"""
                <h2>🧬 Contig-based Analysis Summary</h2>
                <div class="summary-box">
                    <p><strong>ARGs with Full-length Sequences:</strong> <span class="metric">{len(contigs_df)}</span></p>
                    <p><strong>Unique Gene Families:</strong> <span class="metric">{contigs_df['Gene_Family'].nunique()}</span></p>
                </div>
                
                <h3>Comparison: Read-based vs Contig-based Detection</h3>
                <div class="summary-box">
                    <p><strong>Detected by reads only:</strong> {reads_df['ARO_Term'].nunique() - len(set(reads_df['ARO_Term']) & set(contigs_df['ARO']))}</p>
                    <p><strong>Detected by contigs only:</strong> {contigs_df['ARO'].nunique() - len(set(reads_df['ARO_Term']) & set(contigs_df['ARO']))}</p>
                    <p><strong>Detected by both methods:</strong> {len(set(reads_df['ARO_Term']) & set(contigs_df['ARO']))}</p>
                    <p><em>Note: Read-based typically detects more (including low-abundance ARGs that don't assemble), while contig-based provides genomic context.</em></p>
                </div>
            """
        
        html += """
                <div class="footer">
                    <p>Generated by OpusTaxa RGI Module | CARD Database: <a href="https://card.mcmaster.ca/">https://card.mcmaster.ca/</a></p>
                    <p>Citation: Alcock et al. 2023. CARD 2023: expanded curation, support for machine learning, and resistome prediction at the Comprehensive Antibiotic Resistance Database. Nucleic Acids Research.</p>
                </div>
            </div>
        </body>
        </html>
        """
        
        with open(output.report, 'w') as f:
            f.write(html)