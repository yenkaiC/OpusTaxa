#!/usr/bin/env python3
"""
Build a per-gene table from Prodigal-GV GFF output.

One row per predicted gene, carrying its coordinates, the contig it sits on and
Prodigal's per-gene statistics. This is the table to join against contig-level
results (geNomad virus/plasmid calls, antiSMASH regions) or to filter on before
pulling sequences out of the .faa / .fna files.

The file is written gzip-compressed and streamed line by line, so memory use is
constant no matter how many samples or genes there are.

Usage (standalone):
    python prodigal_gv_gene_table.py --prodigal-dir Data/ProdigalGV \
        --samples sample1 sample2 -o Data/ProdigalGV/table/genes.tsv.gz

Usage (from Snakemake):
    Called via the script: directive with snakemake.params and snakemake.output
"""

import gzip
import os
import re
import sys

FIELDNAMES = [
    "sample", "contig", "contig_length", "gene_id", "start", "end", "strand",
    "length_bp", "length_aa", "partial", "start_type", "rbs_motif",
    "rbs_spacer", "gc_content", "confidence", "score",
]

# "# Sequence Data: seqnum=1;seqlen=5000;seqhdr="NODE_1_length_5000_cov_10.5""
_SEQ_DATA = re.compile(r'seqlen=(\d+);seqhdr="([^"]*)"')


def _attributes(field):
    """Parse the GFF attribute column into a dict."""
    out = {}
    for item in field.rstrip(";").split(";"):
        if "=" in item:
            key, _, value = item.partition("=")
            out[key.strip()] = value.strip()
    return out


def parse_gff(gff_path, sample_id, handle):
    """Stream one sample's GFF, writing rows to an open output handle."""
    genes = 0
    contig_length = ""
    with open(gff_path) as gff:
        for line in gff:
            line = line.rstrip("\n")
            if line.startswith("#"):
                match = _SEQ_DATA.search(line)
                if match:
                    # Prodigal records the full contig length per sequence; keep
                    # it so coding density can be computed downstream.
                    contig_length = match.group(1)
                continue
            if not line.strip():
                continue

            parts = line.split("\t")
            if len(parts) < 9:
                continue
            contig, _, _, start, end, score, strand, _, attrs = parts[:9]
            attributes = _attributes(attrs)

            try:
                length_bp = int(end) - int(start) + 1
            except ValueError:
                length_bp = ""

            # A complete gene (partial=00) includes its stop codon; a partial
            # one does not, so only subtract the stop where there is one.
            length_aa = ""
            if isinstance(length_bp, int):
                codons = length_bp // 3
                length_aa = codons - 1 if attributes.get("partial") == "00" else codons

            handle.write("\t".join(str(v) for v in [
                sample_id,
                contig,
                contig_length,
                attributes.get("ID", ""),
                start,
                end,
                strand,
                length_bp,
                length_aa,
                attributes.get("partial", ""),
                attributes.get("start_type", ""),
                attributes.get("rbs_motif", ""),
                attributes.get("rbs_spacer", ""),
                attributes.get("gc_cont", ""),
                attributes.get("conf", ""),
                score,
            ]) + "\n")
            genes += 1
    return genes


def build_table(prodigal_dir, samples, output_path):
    os.makedirs(os.path.dirname(output_path) or ".", exist_ok=True)
    opener = gzip.open if output_path.endswith(".gz") else open
    total = 0
    with opener(output_path, "wt") as handle:
        handle.write("\t".join(FIELDNAMES) + "\n")
        for sample in samples:
            gff_path = os.path.join(prodigal_dir, sample, f"{sample}_genes.gff")
            if not os.path.exists(gff_path):
                print(f"WARNING: no GFF found for {sample} at {gff_path}",
                      file=sys.stderr)
                continue
            n = parse_gff(gff_path, sample, handle)
            total += n
            print(f"{sample}: {n} genes", file=sys.stderr)
    return total


# ── Snakemake entry point ────────────────────────────────────────────────────
try:
    snakemake  # noqa: F821 — injected by Snakemake at runtime

    total = build_table(
        snakemake.params.prodigal_dir,
        snakemake.params.samples,
        snakemake.output.genes,
    )
    print(f"Wrote {total} genes from {len(snakemake.params.samples)} sample(s)")

except NameError:
    import argparse

    parser = argparse.ArgumentParser(
        description="Build a per-gene table from Prodigal-GV GFF output")
    parser.add_argument("--prodigal-dir", required=True,
                        help="Base Prodigal-GV output directory")
    parser.add_argument("--samples", nargs="+", required=True, help="Sample names")
    parser.add_argument("-o", "--output", required=True,
                        help="Output TSV (.gz is compressed)")
    args = parser.parse_args()

    total = build_table(args.prodigal_dir, args.samples, args.output)
    print(f"Wrote {total} genes from {len(args.samples)} sample(s) to {args.output}")
