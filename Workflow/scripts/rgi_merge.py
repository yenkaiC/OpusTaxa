#!/usr/bin/env python3
"""
Merge RGI results across all samples into a single TSV table.
Adds a 'Sample' column extracted from the filename.

Usage (standalone):
    python rgi_merge.py --input sample1_rgi.txt sample2_rgi.txt -o rgi_merged.tsv

Usage (from Snakemake):
    Called via script: directive with snakemake.input and snakemake.output
"""

import csv
import os
import sys


def merge_rgi_tables(txt_files, output_path, log_path=None):
    """Merge multiple RGI .txt result files into one TSV with a Sample column."""
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    header_written = False
    with open(output_path, "w", newline="") as out_f:
        writer = None
        for txt_file in txt_files:
            sample = os.path.basename(txt_file).replace("_rgi.txt", "")
            with open(txt_file, "r") as in_f:
                reader = csv.DictReader(in_f, delimiter="\t")
                if not header_written:
                    fieldnames = ["Sample"] + reader.fieldnames
                    writer = csv.DictWriter(out_f, fieldnames=fieldnames, delimiter="\t")
                    writer.writeheader()
                    header_written = True
                for row in reader:
                    row["Sample"] = sample
                    writer.writerow(row)

    total = sum(1 for line in open(output_path)) - 1  # minus header
    msg = f"Merged {len(txt_files)} samples, {total} total AMR hits\n"
    print(msg, end="")

    if log_path:
        os.makedirs(os.path.dirname(log_path), exist_ok=True)
        with open(log_path, "w") as log_f:
            log_f.write(msg)


# ── Snakemake entry point ────────────────────────────────────────────────────
try:
    snakemake  # noqa: F821

    merge_rgi_tables(
        txt_files=snakemake.input.txt_files,
        output_path=snakemake.output.merged,
        log_path=snakemake.log[0] if snakemake.log else None,
    )

except NameError:
    # ── Standalone CLI entry point ────────────────────────────────────────
    import argparse

    parser = argparse.ArgumentParser(description="Merge RGI result tables")
    parser.add_argument("--input", nargs="+", required=True, help="RGI .txt files")
    parser.add_argument("-o", "--output", required=True, help="Output merged TSV")
    parser.add_argument("--log", default=None, help="Log file")
    args = parser.parse_args()

    merge_rgi_tables(args.input, args.output, args.log)
