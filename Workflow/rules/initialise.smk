## Declare Directories
# Databases
DB_dir = config['databaseDirectory']
nohumanDB_dir = DB_dir + "/nohuman/HPRC.r2/db"
metaphlanDB_dir = DB_dir + "/metaphlan"
singlemDB_dir = DB_dir + "/singlem"
humannDB_dir = DB_dir + "/humann"
kraken2DB_dir = DB_dir + "/kraken2"
cardDB_dir = DB_dir + "/card"
# File locations
input_dir = config['rawFastQDirectory']
clean_dir = config['trimmedFastQDirectory']
nohuman_dir = config['nohumanDirectory']
metaphlan_dir = config['metaphlanDirectory']
singlem_dir = config['singlemDirectory']
multiqc_dir = config['multiQCDirectory']
metaspades_dir = config['metaspadesDirectory']
mlp_dir = config['mlpDirectory']
humann_dir   = config['humannDirectory']
kraken2_dir = config['kraken2Directory']
rgi_dir = config['rgiDirectory']
antismash_dir = config['antismashDirectory']

# Quality Control
qc_dir = config['qcOutputDirectory']
raw_qc_dir = qc_dir + "/Step_1_Raw"
fastp_qc_dir = qc_dir + "/Step_2_FastP"
nohuman_qc_dir = qc_dir + "/Step_3_NoHuman"
# Log
log_dir = config['logDirectory']

# Flags
run_metaphlan = str(config.get("metaphlan", True)).lower() not in ("false", "0", "no")
run_singlem = str(config.get("singlem", True)).lower() not in ("false", "0", "no")
run_kraken2 = str(config.get("kraken2", False)).lower() not in ("false", "0", "no")
run_antismash = str(config.get("antismash", False)).lower() not in ("false", "0", "no")
download_sra = str(config.get("download_sra", False)).lower() not in ("false", "0", "no")
run_test = str(config.get("test_mode", False)).lower() not in ("false", "0", "no")
if run_test:
    input_dir = "Misc/Test/Raw_FastQ"
run_metaspades = str(config.get("metaspades", False)).lower() not in ("false", "0", "no")
run_mlp = str(config.get("mlp", False)).lower() not in ("false", "0", "no")
run_humann = str(config.get("humann", False)).lower() not in ("false", "0", "no")
run_rgi = str(config.get("rgi", True)).lower() not in ("false", "0", "no")

# Read SRA IDs if download_sra is enabled
import os
SRA_IDS = []
if download_sra and os.path.exists("sra_id.txt"):
    with open("sra_id.txt", "r") as f:
        SRA_IDS = [line.strip() for line in f if line.strip()]

# ── Flexible FASTQ sample detection ──────────────────────────────────────────
# Detects paired-end FASTQ files regardless of naming convention and creates
# symlinks to the internal standard: {sample}_R1_001.fastq.gz / _R2_001.fastq.gz
#
# Supported naming patterns (R1 shown, R2 analogous):
#   Illumina bcl2fastq:  {sample}_S1_L001_R1_001.fastq.gz
#   Illumina (no lane):  {sample}_S1_R1_001.fastq.gz
#   Standard:            {sample}_R1_001.fastq.gz
#   Simple paired:       {sample}_R1.fastq.gz
#   SRA / ENA:           {sample}_1.fastq.gz
#   Dot-separated:       {sample}.R1.fastq.gz  /  {sample}.1.fastq.gz
#
# Also accepts .fq.gz extension alongside .fastq.gz.
# ──────────────────────────────────────────────────────────────────────────────

# Regex to match R1 files across all supported patterns.
# Captures: (sample_name) and identifies the read-1 indicator.
_R1_PATTERNS = [
    # Illumina full:  sample_S1_L001_R1_001.fastq.gz
    (re.compile(r'^(.+?)_S\d+_L\d+_R1_001\.(?:fastq|fq)\.gz$'), 'illumina_full'),
    # Illumina no-lane: sample_S1_R1_001.fastq.gz
    (re.compile(r'^(.+?)_S\d+_R1_001\.(?:fastq|fq)\.gz$'), 'illumina_nolane'),
    # Standard: sample_R1_001.fastq.gz
    (re.compile(r'^(.+?)_R1_001\.(?:fastq|fq)\.gz$'), 'standard'),
    # Simple: sample_R1.fastq.gz
    (re.compile(r'^(.+?)_R1\.(?:fastq|fq)\.gz$'), 'simple'),
    # SRA: sample_1.fastq.gz  (must not match S1_L001 etc.)
    (re.compile(r'^(.+?)_1\.(?:fastq|fq)\.gz$'), 'sra'),
    # Dot-separated R1: sample.R1.fastq.gz
    (re.compile(r'^(.+?)\.R1\.(?:fastq|fq)\.gz$'), 'dot_R1'),
    # Dot-separated 1: sample.1.fastq.gz
    (re.compile(r'^(.+?)\.1\.(?:fastq|fq)\.gz$'), 'dot_1'),
]

def _r2_filename(r1_filename, pattern_type):
    """Given an R1 filename and its pattern type, return the expected R2 filename."""
    replacements = {
        'illumina_full':  ('_R1_001.', '_R2_001.'),
        'illumina_nolane': ('_R1_001.', '_R2_001.'),
        'standard':       ('_R1_001.', '_R2_001.'),
        'simple':         ('_R1.', '_R2.'),
        'sra':            ('_1.', '_2.'),
        'dot_R1':         ('.R1.', '.R2.'),
        'dot_1':          ('.1.', '.2.'),
    }
    old, new = replacements[pattern_type]
    return r1_filename.replace(old, new, 1)

def detect_samples(directory):
    """Scan directory for paired-end FASTQ files and return {sample: (r1_path, r2_path)}."""
    detected = {}
    if not os.path.isdir(directory):
        return detected
    for fname in sorted(os.listdir(directory)):
        fpath = os.path.join(directory, fname)
        if not os.path.isfile(fpath):
            continue
        for pattern, ptype in _R1_PATTERNS:
            m = pattern.match(fname)
            if m:
                sample = m.group(1)
                r2_fname = _r2_filename(fname, ptype)
                r2_path = os.path.join(directory, r2_fname)
                if os.path.isfile(r2_path):
                    # Skip if this sample was already detected by a higher-priority pattern
                    if sample not in detected:
                        detected[sample] = (fpath, r2_path)
                break  # Only match the first (highest priority) pattern per file
    return detected

_detected = detect_samples(input_dir)
SAMPLES = list(set(list(_detected.keys()) + SRA_IDS))

# Print detected samples for debugging
if _detected:
    print(f"Detected {len(_detected)} sample(s) in {input_dir}/:")
    for s in sorted(_detected.keys()):
        r1 = os.path.basename(_detected[s][0])
        print(f"  {s}  ←  {r1}")

if not SAMPLES:
    print(f"WARNING: No samples detected in {input_dir}/ and no SRA IDs provided.")

## Rule to standardize filenames via symlink
# Creates symlinks so all downstream rules can use the standard naming convention.
# Files already in standard format will match as-is (symlink points to itself → skipped).
rule standardize_filenames:
    input:
        r1 = lambda wc: _detected[wc.sample][0] if wc.sample in _detected else input_dir + "/{sample}_1.fastq.gz".format(sample=wc.sample),
        r2 = lambda wc: _detected[wc.sample][1] if wc.sample in _detected else input_dir + "/{sample}_2.fastq.gz".format(sample=wc.sample),
    output:
        r1 = input_dir + "/{sample}_R1_001.fastq.gz",
        r2 = input_dir + "/{sample}_R2_001.fastq.gz"
    log:
        log_dir + "/file_rename/{sample}.log"
    run:
        import os
        for src, dst in [(input.r1, output.r1), (input.r2, output.r2)]:
            src_abs = os.path.abspath(src)
            dst_abs = os.path.abspath(dst)
            if src_abs == dst_abs:
                # Already in standard format, nothing to do
                shell(f"echo 'Already standard: {src}' > {log}")
            elif os.path.exists(dst_abs):
                shell(f"echo 'Target exists: {dst}' >> {log}")
            else:
                os.symlink(src_abs, dst_abs)
                shell(f"echo 'Symlinked {src} → {dst}' >> {log}")





## Old file patterns
#samples_standard, = glob_wildcards(input_dir + "/{sample}_R1_001.fastq.gz") # SAGC
#samples_srr, = glob_wildcards(input_dir + "/{sample}_1.fastq.gz") # SRA
#
## All samples (combination of both)
#SAMPLES = list(set(samples_standard + samples_srr + SRA_IDS))
#
### Rule to standardize SRR filenames
#rule standardize_filenames:
#    input:
#        r1 = input_dir + "/{sample}_1.fastq.gz",
#        r2 = input_dir + "/{sample}_2.fastq.gz"
#    output:
#        r1 = input_dir + "/{sample}_R1_001.fastq.gz",
#        r2 = input_dir + "/{sample}_R2_001.fastq.gz"
#    log:
#        log_dir + "/file_rename/{sample}.log"
#    shell:
#        """
#        mv {input.r1} {output.r1}
#        mv {input.r2} {output.r2} 2> {log}
#        """