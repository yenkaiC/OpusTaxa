## Provenance record: OpusTaxa version, tool versions, database versions.
## Included last in the Snakefile so the database-name constants defined in the
## other rule files (METAPHLAN_INDEX, SINGLEM_METAPACKAGE, SYLPH_DB_NAME ...)
## are already in scope.

versions_file = config.get("versionsFile", "Data/opustaxa_versions.txt")

try:
    from snakemake import __version__ as SNAKEMAKE_VERSION
except ImportError:
    SNAKEMAKE_VERSION = "unknown"


def provenance_db_inputs(wildcards=None):
    """Databases the run needs, so versions are read after they are installed."""
    needed = []
    if run_nohuman:
        needed.append(nohumanDB_dir + "/taxo.k2d")
    if run_metaphlan or run_strainphlan or run_humann:
        needed.append(metaphlanDB_dir + "/.download_complete")
    if run_singlem:
        needed.append(singlemDB_dir + "/" + SINGLEM_METAPACKAGE)
    if run_kraken2:
        needed.append(kraken2DB_dir + "/.download_complete")
    if run_humann:
        needed += [
            humannDB_dir + "/.chocophlan_download_complete",
            humannDB_dir + "/.uniref_download_complete",
            humannDB_dir + "/.utility_mapping_download_complete",
        ]
    if run_rgi:
        needed.append(DB_dir + "/card/.download_complete")
    if run_antismash:
        needed.append(DB_dir + "/antismash/.databases_downloaded")
    if run_genomad:
        needed.append(DB_dir + "/genomad/.download_complete")
    if run_sylph:
        needed += [sylphDB_dir + "/" + SYLPH_DB_NAME,
                   sylphDB_dir + "/.sylph_tax_downloaded"]
    if run_sylph_viral:
        needed.append(sylphDB_dir + "/" + SYLPH_VIRAL_DB_NAME)
    return needed


rule write_provenance:
    input:
        provenance_db_inputs
    output:
        versions = versions_file
    params:
        repo       = workflow.basedir,
        db_dir     = DB_dir,
        containers = CONTAINERS,
        samples    = SAMPLES,
        deployment = ("containers (Singularity/Apptainer)" if use_containers
                      else "conda (Workflow/envs)"),
        enabled = {
            "nohuman": run_nohuman,
            "download_sra": download_sra,
            "nonpareil": run_nonpareil,
            "metaphlan": run_metaphlan,
            "strainphlan": run_strainphlan,
            "singlem": run_singlem,
            "kraken2": run_kraken2,
            "sylph": run_sylph,
            "sylph_viral": run_sylph_viral,
            "metaspades": run_metaspades,
            "humann": run_humann,
            "rgi": run_rgi,
            "antismash": run_antismash,
            "prodigal_gv": run_prodigalgv,
            "genomad": run_genomad,
            "mlp": run_mlp,
            "hecatomb": run_hecatomb,
        },
        declared = {
            "nohuman":   "HPRC.r2",
            "metaphlan": METAPHLAN_INDEX,
            "singlem":   SINGLEM_METAPACKAGE,
            "kraken2":   "k2_pluspf_16_GB_20251015",
            "humann":    "chocophlan v201901_v31 / uniref90 v201901b / mapping v201901b",
            "card":      "latest (CARD publishes no versioned URL)",
            "antismash": "bundled with the antiSMASH release above",
            "genomad":   "latest at time of download",
            "sylph":     SYLPH_DB_NAME + " + " + SYLPH_TAX_NAME,
        },
        settings = {
            "snakemake_version": SNAKEMAKE_VERSION,
            "input directory":   input_dir,
            "reads analysed":    reads_dir,
            "environmental mode": environmental,
            "SRA download":      download_sra,
            "MetaPhlAn index":   METAPHLAN_INDEX,
        },
    log:
        log_dir + "/provenance.log"
    resources:
        mem_mb = get_mem("write_provenance", 2000),
        runtime = 10
    threads: 1
    script:
        workflow.basedir + "/Workflow/scripts/write_provenance.py"
