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
        
        for area in record.get("areas", []):
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
            
            # Extract knownclusterblast hits if available
            most_similar = ""
            for module_name, module_data in record.get("modules", {}).items():
                if "knowncluster" in module_name.lower():
                    region_results = module_data.get("region_results", {})
                    for region_key, region_data in region_results.items():
                        hits = region_data.get("ranking", [])
                        for hit in hits[:1]:  # Top hit only
                            if isinstance(hit, list) and len(hit) >= 2:
                                hit_info = hit[0]
                                if isinstance(hit_info, dict):
                                    most_similar = hit_info.get("description", "")
            
            regions.append({
                "sample": sample_id,
                "contig": record_id,
                "region_start": region_start,
                "region_end": region_end,
                "region_length": region_length,
                "bgc_type": product_str,
                "contig_edge": contig_edge,
                "most_similar_known_bgc": most_similar,
            })
    
    return regions


FIELDNAMES = [
    "sample", "contig", "region_start", "region_end",
    "region_length", "bgc_type", "contig_edge",
    "most_similar_known_bgc"
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
