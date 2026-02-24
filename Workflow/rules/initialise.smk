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

import os
import re
from pathlib import Path

# Detect all FASTQ pairs in input directory
def detect_all_samples(directory):
    """Detect all paired FASTQ files regardless of naming convention."""
    if not os.path.isdir(directory):
        return {}
    
    files = sorted([f for f in os.listdir(directory) if f.endswith(('.fastq.gz', '.fq.gz'))])
    samples = {}
    
    # Group files by potential sample name
    for fname in files:
        # Try different R1 patterns
        for pattern, read_num in [
            (r'^(.+)_S\d+_L\d+_R1_001\.(?:fastq|fq)\.gz$', 'R1'),  # Illumina full
            (r'^(.+)_S\d+_R1_001\.(?:fastq|fq)\.gz$', 'R1'),        # Illumina no lane
            (r'^(.+)_R1_001\.(?:fastq|fq)\.gz$', 'R1'),              # Standard
            (r'^(.+)_R1\.(?:fastq|fq)\.gz$', 'R1'),                  # Simple
            (r'^(.+)_1\.(?:fastq|fq)\.gz$', '1'),                    # SRA
            (r'^(.+)\.R1\.(?:fastq|fq)\.gz$', 'R1_dot'),             # Dot-separated
            (r'^(.+)\.1\.(?:fastq|fq)\.gz$', '1_dot'),               # Dot-separated SRA
        ]:
            m = re.match(pattern, fname)
            if m:
                sample = m.group(1)
                if sample not in samples:
                    samples[sample] = {}
                samples[sample]['r1'] = os.path.join(directory, fname)
                samples[sample]['pattern'] = read_num
                break
    
    # Now find matching R2 files
    for sample, info in list(samples.items()):
        r1_path = info['r1']
        r1_file = os.path.basename(r1_path)
        
        # Determine R2 filename based on pattern
        if info['pattern'] == 'R1':
            r2_file = r1_file.replace('_R1_001.', '_R2_001.').replace('_R1.', '_R2.')
        elif info['pattern'] == '1':
            r2_file = r1_file.replace('_1.', '_2.')
        elif info['pattern'] == 'R1_dot':
            r2_file = r1_file.replace('.R1.', '.R2.')
        elif info['pattern'] == '1_dot':
            r2_file = r1_file.replace('.1.', '.2.')
        else:
            del samples[sample]
            continue
        
        r2_path = os.path.join(directory, r2_file)
        if os.path.isfile(r2_path):
            samples[sample]['r2'] = r2_path
        else:
            # R2 not found, remove this sample
            del samples[sample]
    
    return samples

_detected = detect_all_samples(input_dir)

SAMPLES = list(set(list(_detected.keys()) + SRA_IDS))

if _detected:
    print(f"Detected {len(_detected)} sample(s) in {input_dir}/:")
    for s in sorted(_detected.keys()):
        r1 = os.path.basename(_detected[s]['r1'])
        print(f"  {s}  ←  {r1}")

if not SAMPLES:
    print(f"WARNING: No samples detected in {input_dir}/ and no SRA IDs provided.")



## Rule to standardize filenames via symlink
# Only runs for files that don't already match {sample}_R1_001.fastq.gz
# Creates symlinks so downstream rules use the standard naming convention.
# Original files are never modified.
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
        sample = "|".join(re.escape(s) for s in _samples_need_symlink) if _samples_need_symlink else "NONE"
    shell:
        """
        ln -sf $(readlink -f {input.r1}) {output.r1}
        ln -sf $(readlink -f {input.r2}) {output.r2}
        echo "Symlinked {input.r1} → {output.r1}" > {log}
        echo "Symlinked {input.r2} → {output.r2}" >> {log}
        """