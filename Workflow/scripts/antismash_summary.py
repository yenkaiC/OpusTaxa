#!/usr/bin/env python3
"""
Parse antiSMASH JSON output files into a summary TSV table.
Extracts BGC regions, their types, positions, and known cluster hits.

Finds the JSON file automatically within each sample's antiSMASH output
directory, since the filename varies depending on the input (e.g.
contigs.json, contigs_filtered.json, scaffolds.json).

Usage (standalone):
    python antismash_summary.py --antismash-dir Data/AntiSMASH --samples sample1 sample2 -o summary.tsv

Usage (from Snakemake):
    Called via script: directive with snakemake.params and snakemake.output
"""

import json
import csv
import sys
import os
import glob


def find_json(sample_dir):
    """Find the antiSMASH JSON file in a sample directory."""
    json_files = glob.glob(os.path.join(sample_dir, "*.json"))
    # Filter out region-specific JSONs if any; we want the main output
    main_jsons = [f for f in json_files if not os.path.basename(f).startswith("NODE_")]
    if main_jsons:
        return main_jsons[0]
    elif json_files:
        return json_files[0]
    return None


def parse_antismash_json(json_path, sample_id=None):
    """Parse a single antiSMASH JSON file and return a list of BGC region dicts."""
    
    if sample_id is None:
        sample_id = os.path.basename(os.path.dirname(json_path))
    
    with open(json_path) as f:
        data = json.load(f)
    
    regions = []
    
    for record in data.get("records", []):
        record_id = record.get("id", "unknown")

        # KnownClusterBlast results live under the clusterblast module, keyed by
        # region number (1-based, in the same order as the areas below).
        clusterblast = record.get("modules", {}).get("antismash.modules.clusterblast", {})
        known_by_region = {
            result.get("region_number"): result
            for result in clusterblast.get("knowncluster", {}).get("results", [])
        }

        for region_number, area in enumerate(record.get("areas", []), start=1):
            region_start = area.get("start", "")
            region_end = area.get("end", "")
            products = area.get("products", [])
            product_str = ";".join(products) if products else "unknown"
            
            # Calculate region length
            try:
                region_length = int(region_end) - int(region_start)
            except (ValueError, TypeError):
                region_length = ""
            
            # Check if region is on contig edge
            contig_edge = "No"
            try:
                seq_length = len(record.get("seq", {}).get("data", ""))
                if seq_length > 0:
                    if int(region_start) <= 1 or int(region_end) >= seq_length:
                        contig_edge = "Yes"
            except (ValueError, TypeError):
                contig_edge = "unknown"
            
            # Extract the top KnownClusterBlast hit for this region, if any.
            # ranking entries are [reference_cluster, scoring]; the cluster dict
            # holds the MIBiG accession and description.
            most_similar = ""
            known_accession = ""
            ranking = (known_by_region.get(region_number) or {}).get("ranking") or []
            if ranking and isinstance(ranking[0], (list, tuple)) and isinstance(ranking[0][0], dict):
                top_hit = ranking[0][0]
                most_similar = top_hit.get("description", "")
                known_accession = top_hit.get("accession", "")
            
            regions.append({
                "sample": sample_id,
                "contig": record_id,
                "region_start": region_start,
                "region_end": region_end,
                "region_length": region_length,
                "bgc_type": product_str,
                "contig_edge": contig_edge,
                "most_similar_known_bgc": most_similar,
                "known_bgc_accession": known_accession,
            })
    
    return regions


FIELDNAMES = [
    "sample", "contig", "region_start", "region_end",
    "region_length", "bgc_type", "contig_edge",
    "most_similar_known_bgc", "known_bgc_accession"
]


def write_table(all_regions, output_path):
    """Write regions to a TSV file."""
    with open(output_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=FIELDNAMES, delimiter="\t")
        writer.writeheader()
        writer.writerows(all_regions)


# ── Snakemake entry point ────────────────────────────────────────────────────
try:
    snakemake  # noqa: F821 — injected by Snakemake at runtime

    antismash_dir = snakemake.params.antismash_dir
    samples = snakemake.params.samples
    output_file = snakemake.output.summary

    all_regions = []
    for sample in samples:
        sample_dir = os.path.join(antismash_dir, sample)
        json_path = find_json(sample_dir)
        if json_path:
            regions = parse_antismash_json(json_path, sample_id=sample)
            all_regions.extend(regions)
        else:
            print(f"WARNING: No JSON found in {sample_dir}", file=sys.stderr)

    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    write_table(all_regions, output_file)
    print(f"Wrote {len(all_regions)} BGC regions from {len(samples)} sample(s)")

except NameError:
    # ── Standalone CLI entry point ────────────────────────────────────────
    import argparse

    parser = argparse.ArgumentParser(description="Parse antiSMASH outputs into a summary table")
    parser.add_argument("--antismash-dir", required=True, help="Base antiSMASH output directory")
    parser.add_argument("--samples", nargs="+", required=True, help="Sample names")
    parser.add_argument("-o", "--output", required=True, help="Output TSV file")
    args = parser.parse_args()

    all_regions = []
    for sample in args.samples:
        sample_dir = os.path.join(args.antismash_dir, sample)
        json_path = find_json(sample_dir)
        if json_path:
            regions = parse_antismash_json(json_path, sample_id=sample)
            all_regions.extend(regions)
        else:
            print(f"WARNING: No JSON found in {sample_dir}", file=sys.stderr)

    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    write_table(all_regions, args.output)
    print(f"Wrote {len(all_regions)} BGC regions from {len(args.samples)} sample(s) to {args.output}")