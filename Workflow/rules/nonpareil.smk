## Nonpareil - redundancy-based estimation of metagenome coverage and the
## sequencing effort required for near-complete coverage.
## Runs on host-removed reads (requires nohuman).
##
## Nonpareil operates on SINGLE reads, so only R1 is used (standard practice;
## the second mate adds correlated redundancy and is not recommended as input).
## The k-mer kernel is used by default: ~300x faster than the alignment kernel
## with near-identical coverage/diversity estimates (Rodriguez-R et al. 2018).

nonpareil_dir = config.get('nonpareilDirectory', 'Reports/Nonpareil/npo')
nonpareil_report_dir = config.get('nonpareilReportDirectory', 'Reports/Nonpareil')
run_nonpareil = str(config.get("nonpareil", False)).lower() not in ("false", "0", "no")

# Kernel: "kmer" (recommended, fast) or "alignment". fastq is recommended for kmer.
NONPAREIL_KERNEL = config.get("nonpareil_kernel", "kmer")


## Run Nonpareil per sample on the host-removed R1 reads.
## Nonpareil cannot read gzipped input reliably across versions, so R1 is
## streamed to a temporary uncompressed FASTQ first.
rule nonpareil_run:
    input:
        r1 = nohuman_dir + "/{sample}_R1_001.fastq.gz"
    output:
        npo = nonpareil_dir + "/{sample}.npo"
    conda:
        workflow.basedir + "/Workflow/envs/nonpareil.yaml"
    container:
        get_container("nonpareil")
    params:
        prefix = nonpareil_dir + "/{sample}",
        kernel = NONPAREIL_KERNEL,
        tmp    = nonpareil_dir + "/{sample}.tmp.fastq"
    threads: get_threads("nonpareil")
    resources:
        mem_mb = 20000,
        runtime = 240
    log:
        log_dir + "/nonpareil/{sample}.log"
    shell:
        """
        mkdir -p $(dirname {output.npo})
        mkdir -p $(dirname {log})

        # Nonpareil needs uncompressed single-end reads.
        zcat {input.r1} > {params.tmp}

        nonpareil \
            -s {params.tmp} \
            -T {params.kernel} \
            -f fastq \
            -b {params.prefix} \
            -t {threads} 2> {log}

        rm -f {params.tmp}
        """


## Build the report: merged per-sample summary table + overlaid coverage curves.
rule nonpareil_report:
    input:
        npo = expand(nonpareil_dir + "/{sample}.npo", sample=SAMPLES)
    output:
        table = nonpareil_report_dir + "/table/nonpareil_summary.tsv",
        plot  = nonpareil_report_dir + "/table/nonpareil_curves.pdf"
    conda:
        workflow.basedir + "/Workflow/envs/nonpareil.yaml"
    container:
        get_container("nonpareil")
    params:
        script = workflow.basedir + "/Workflow/scripts/nonpareil_report.R"
    resources:
        mem_mb = 16000,
        runtime = 60
    threads: 4
    log:
        log_dir + "/nonpareil/report.log"
    shell:
        """
        mkdir -p $(dirname {output.table})
        mkdir -p $(dirname {log})
        Rscript {params.script} \
            {output.table} \
            {output.plot} \
            {input.npo} 2> {log}
        """
