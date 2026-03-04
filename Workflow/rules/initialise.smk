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
input_dir = config.get('inputFastQDirectory', config['rawFastQDirectory']) # Use inputFastQDirectory if provided, otherwise fall back to rawFastQDirectory
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

import re
from pathlib import Path

# Each tuple: (compiled_regex, pattern_type, needs_standardisation)
# needs_standardisation = False means the file already matches {sample}_R1_001.fastq.gz
_R1_PATTERNS = [
    # Illumina full:  sample_S1_L001_R1_001.fastq.gz  →  sample_S1_L001 as sample name
    (re.compile(r'^(.+?_S\d+_L\d+)_R1_001\.(?:fastq|fq)\.gz$'), 'illumina_full', False),
    # Illumina no-lane: sample_S1_R1_001.fastq.gz  →  sample_S1 as sample name
    (re.compile(r'^(.+?_S\d+)_R1_001\.(?:fastq|fq)\.gz$'), 'illumina_nolane', False),
    # Standard: sample_R1_001.fastq.gz  →  already standard
    (re.compile(r'^(.+?)_R1_001\.fastq\.gz$'), 'standard', False),
    # Standard with .fq.gz: sample_R1_001.fq.gz  →  needs symlink to .fastq.gz
    (re.compile(r'^(.+?)_R1_001\.fq\.gz$'), 'standard_fq', True),
    # Simple: sample_R1.fastq.gz
    (re.compile(r'^(.+?)_R1\.(?:fastq|fq)\.gz$'), 'simple', True),
    # SRA: sample_1.fastq.gz
    (re.compile(r'^(.+?)_1\.(?:fastq|fq)\.gz$'), 'sra', True),
    # Dot-separated R1: sample.R1.fastq.gz
    (re.compile(r'^(.+?)\.R1\.(?:fastq|fq)\.gz$'), 'dot_R1', True),
    # Dot-separated 1: sample.1.fastq.gz
    (re.compile(r'^(.+?)\.1\.(?:fastq|fq)\.gz$'), 'dot_1', True),
]

def _r2_filename(r1_filename, pattern_type):
    """Given an R1 filename and its pattern type, return the expected R2 filename."""
    replacements = {
        'illumina_full':  ('_R1_001.', '_R2_001.'),
        'illumina_nolane': ('_R1_001.', '_R2_001.'),
        'standard':       ('_R1_001.', '_R2_001.'),
        'standard_fq':    ('_R1_001.', '_R2_001.'),
        'simple':         ('_R1.', '_R2.'),
        'sra':            ('_1.', '_2.'),
        'dot_R1':         ('.R1.', '.R2.'),
        'dot_1':          ('.1.', '.2.'),
    }
    old, new = replacements[pattern_type]
    return r1_filename.replace(old, new, 1)

def detect_samples(directory):
    """Scan directory for paired-end FASTQ files.

    Returns:
        dict: {sample_name: (r1_path, r2_path, needs_standardisation)}
    """
    detected = {}
    if not os.path.isdir(directory):
        return detected
    for fname in sorted(os.listdir(directory)):
        fpath = os.path.join(directory, fname)
        if not os.path.isfile(fpath) and not os.path.islink(fpath):
            continue
        for pattern, ptype, needs_std in _R1_PATTERNS:
            m = pattern.match(fname)
            if m:
                sample = m.group(1)
                r2_fname = _r2_filename(fname, ptype)
                r2_path = os.path.join(directory, r2_fname)
                if os.path.exists(r2_path):
                    if sample not in detected:
                        detected[sample] = (fpath, r2_path, needs_std)
                break
    return detected

_detected = detect_samples(input_dir)

# Add SRA samples to _detected
if download_sra and SRA_IDS:
    for sra_id in SRA_IDS:
        if sra_id not in _detected:
            _detected[sra_id] = {
                'r1': input_dir + f"/{sra_id}_1.fastq.gz",
                'r2': input_dir + f"/{sra_id}_2.fastq.gz",
                'pattern': '1'
            }

# Samples that need symlinks vs those already in standard naming
_samples_need_symlink = {s: (r1, r2) for s, (r1, r2, needs_std) in _detected.items() if needs_std}
_samples_already_standard = {s for s, (_, _, needs_std) in _detected.items() if not needs_std}

SAMPLES = sorted(set(list(_detected.keys()) + SRA_IDS))

# Print detected samples for debugging
if _detected:
    print(f"Detected {len(_detected)} sample(s) in {input_dir}/:")
    for s in sorted(_detected.keys()):
        # Handle both tuple format (from detect_all_samples) and dict format (from SRA)
        if isinstance(_detected[s], dict):
            # Dictionary format (SRA samples)
            r1 = os.path.basename(_detected[s]['r1'])
            tag = " (SRA)"
        else:
            # Tuple format (detected files)
            r1 = os.path.basename(_detected[s][0])
            tag = "" if _detected[s][2] else " (standard)"
        print(f"  {s}  ←  {r1}{tag}")

if not SAMPLES:
    print(f"WARNING: No samples detected in {input_dir}/ and no SRA IDs provided.")

## Rule to standardize filenames via symlink
# Only runs for files that don't already match {sample}_R1_001.fastq.gz
# Creates symlinks so downstream rules use the standard naming convention.
# Original files are never modified.
_symlink_constraint = "|".join(re.escape(s) for s in _samples_need_symlink) if _samples_need_symlink else "IMPOSSIBLE_MATCH_PLACEHOLDER"

rule standardize_filenames:
    input:
        r1 = lambda wc: _samples_need_symlink[wc.sample][0],
        r2 = lambda wc: _samples_need_symlink[wc.sample][1],
    output:
        r1 = input_dir + "/{sample}_R1_001.fastq.gz",
        r2 = input_dir + "/{sample}_R2_001.fastq.gz"
    log:
        log_dir + "/file_rename/{sample}.log"
    wildcard_constraints:
        sample = _symlink_constraint
    resources:
        mem_mb = 4000,
        runtime = 60
    shell:
        """
        ln -sf $(readlink -f {input.r1}) {output.r1}
        ln -sf $(readlink -f {input.r2}) {output.r2}
        echo "Symlinked {input.r1} → {output.r1}" > {log}
        echo "Symlinked {input.r2} → {output.r2}" >> {log}
        """
