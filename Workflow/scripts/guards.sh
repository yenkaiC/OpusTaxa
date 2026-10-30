#!/bin/sh
# OpusTaxa shell guards
# =====================
# Helpers for samples that legitimately contain (almost) no data: negative
# controls, extraction blanks, and samples that were not sequenced deeply
# enough. Most bioinformatics tools are written for a sample that has data and
# exit non-zero when handed one that does not, which fails the whole run
# because of one blank well.
#
# Source at the top of a rule's shell block:
#
#     source {GUARDS} {SKIP_dir}
#
# The second argument sets where skip markers are written; it defaults to
# Reports/Skipped if omitted.
#
# POSIX sh only, and nothing beyond coreutils + awk, so these work unchanged
# in every OpusTaxa container and conda environment.

OPUSTAXA_SKIP_DIR="${1:-Reports/Skipped}"


# fasta_has_records FILE
#   Succeeds when FILE exists, is non-empty, and holds at least one record.
fasta_has_records() {
    [ -s "$1" ] || return 1
    grep -q "^>" "$1" 2>/dev/null
}


# fastq_reads_at_least FILE N
#   Succeeds when FILE holds at least N reads. Reads are counted by streaming
#   only the first N*4 lines, so this costs the same on a 50 MB file and a
#   50 GB one. The brace group keeps SIGPIPE from zcat out of `set -o pipefail`.
fastq_reads_at_least() {
    [ -s "$1" ] || return 1
    _want=$(( $2 * 4 ))
    _got=$( { zcat -f -- "$1" 2>/dev/null || true; } | head -n "$_want" | wc -l )
    [ "$_got" -ge "$_want" ]
}


# fastq_reads FILE
#   Prints the exact read count. Decompresses the whole file, so use
#   fastq_reads_at_least for guards and keep this for reporting.
fastq_reads() {
    [ -s "$1" ] || { echo 0; return 0; }
    _lines=$( { zcat -f -- "$1" 2>/dev/null || true; } | wc -l )
    echo $(( _lines / 4 ))
}


# kreport_reads_at FILE LEVEL
#   Prints the number of reads assigned to clades at exactly rank LEVEL
#   ("S", "G", ...) in a Kraken2 report. Column 2 is the clade count, so
#   matching the rank exactly avoids double-counting strains (S1, S2) inside
#   their parent species. Prints 0 for a missing or empty report.
kreport_reads_at() {
    [ -s "$1" ] || { echo 0; return 0; }
    awk -F'\t' -v lvl="$2" '$4 == lvl { s += $2 } END { print s+0 }' "$1" 2>/dev/null \
        || echo 0
}


# tsv_data_rows FILE
#   Prints the number of data rows in a TSV: non-blank lines that do not start
#   with '#'. Used on profiles whose header is present but whose body is empty.
tsv_data_rows() {
    [ -s "$1" ] || { echo 0; return 0; }
    awk 'NF && $0 !~ /^#/ { n++ } END { print n+0 }' "$1" 2>/dev/null || echo 0
}


# tsv_rows_matching FILE PATTERN
#   Prints the number of lines in FILE matching the extended regex PATTERN.
tsv_rows_matching() {
    [ -s "$1" ] || { echo 0; return 0; }
    grep -Ec -- "$2" "$1" 2>/dev/null || echo 0
}


# skip_note TOOL SAMPLE REASON LOGFILE
#   Records that TOOL was skipped for SAMPLE. Writes the reason to the rule's
#   own log and drops a one-line marker file for the end-of-run report.
#   One file per (tool, sample) means no two jobs ever append to the same file,
#   which matters on a parallel filesystem like Setonix's Lustre.
skip_note() {
    mkdir -p "$OPUSTAXA_SKIP_DIR" 2>/dev/null || true
    printf '%s\t%s\t%s\n' "$1" "$2" "$3" > "$OPUSTAXA_SKIP_DIR/$1.$2.tsv" 2>/dev/null || true
    if [ -n "${4:-}" ]; then
        echo "[$1] $2 skipped: $3" >> "$4"
    else
        echo "[$1] $2 skipped: $3" >&2
    fi
}
