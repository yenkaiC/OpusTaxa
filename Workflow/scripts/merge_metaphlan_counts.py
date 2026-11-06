#!/usr/bin/env python3
"""
Merge MetaPhlAn profiles into read-count tables.

MetaPhlAn run with `-t rel_ab_w_read_stats` writes five columns per clade:

    #clade_name  clade_taxid  relative_abundance  coverage  estimated_number_of_reads_from_the_clade

`merge_metaphlan_tables.py` reads only columns 0 and 2, so the counts in
column 4 are discarded. This script merges column 4 instead, and additionally
records each sample's library size from the profile headers:

    #<N> reads processed
    #Estimated reads mapped to known clades: <M>

Those two numbers are what make a count table interpretable. The per-clade
counts sum to the mapped portion only, so without the library size you still
cannot tell whether 1% of a sample is 10 reads or 10,000.

Outputs
    counts_all      one row per clade, one column per sample, estimated reads
    counts_species  the `s__` subset of the above
    library_sizes   per sample: reads processed, mapped, unclassified, fraction

Standard library only - no pandas - so it runs in any environment.

Usage (standalone):
    python merge_metaphlan_counts.py --profiles Data/Metaphlan/*_profile.txt \
        --counts counts_all.txt --species counts_species.txt \
        --library-sizes library_sizes.txt

Usage (from Snakemake):
    Called via the script: directive with snakemake.input / snakemake.output
"""

import os
import re
import sys

# "#1234567 reads processed" / "#1234567 bases processed" (long-read mode)
_PROCESSED = re.compile(r"^#(\d+)\s+(reads|bases)\s+processed\s*$")
# "#Estimated reads mapped to known clades: 123456"
_MAPPED = re.compile(r"^#Estimated\s+(?:reads|bases)\s+mapped to known clades:\s*(\d+)\s*$")

COUNT_COLUMN = "estimated_number_of_reads_from_the_clade"


def sample_name(path):
    """Mirror merge_metaphlan_tables.py so both tables share column names."""
    return os.path.splitext(os.path.basename(path))[0].replace("_profile", "")


def _as_int(value):
    """Counts are integers for short reads; tolerate a float or a '-'."""
    value = value.strip()
    if not value or value == "-":
        return 0
    try:
        return int(value)
    except ValueError:
        try:
            return int(round(float(value)))
        except ValueError:
            return 0


def parse_profile(path):
    """Return (counts_by_clade, taxid_by_clade, stats) for one profile."""
    counts, taxids = {}, {}
    stats = {"reads_processed": 0, "reads_mapped": 0, "unit": "reads"}
    column_names = None

    with open(path) as handle:
        for line in handle:
            line = line.rstrip("\n")
            if not line.strip():
                continue

            if line.startswith("#"):
                match = _PROCESSED.match(line)
                if match:
                    stats["reads_processed"] = int(match.group(1))
                    stats["unit"] = match.group(2)
                    continue
                match = _MAPPED.match(line)
                if match:
                    stats["reads_mapped"] = int(match.group(1))
                    continue
                # The last header line is the column header; keep overwriting
                # so whichever comes last wins, as MetaPhlAn's own merge does.
                fields = line.lstrip("#").split("\t")
                if fields and fields[0].strip() == "clade_name":
                    column_names = [f.strip() for f in fields]
                continue

            fields = line.split("\t")
            if len(fields) < 3:
                continue

            clade = fields[0]
            taxids[clade] = fields[1] if len(fields) > 1 else ""

            # Prefer the named column; fall back to position 4 only if the
            # header was unreadable. A profile written without read stats has
            # no such column, which is an error worth reporting rather than
            # silently filling with zeros.
            index = None
            if column_names and COUNT_COLUMN in column_names:
                index = column_names.index(COUNT_COLUMN)
            elif len(fields) >= 5:
                index = 4
            if index is None or index >= len(fields):
                raise SystemExit(
                    f"ERROR: {path} has no '{COUNT_COLUMN}' column.\n"
                    "       MetaPhlAn must be run with -t rel_ab_w_read_stats "
                    "for read counts to be available."
                )
            counts[clade] = _as_int(fields[index])

    return counts, taxids, stats


def write_counts(out_path, clades, taxids, per_sample, samples, species_only=False):
    with open(out_path, "w") as out:
        out.write("clade_name\tclade_taxid\t" + "\t".join(samples) + "\n")
        for clade in clades:
            if species_only and "s__" not in clade:
                continue
            row = [str(per_sample[s].get(clade, 0)) for s in samples]
            out.write(f"{clade}\t{taxids.get(clade, '')}\t" + "\t".join(row) + "\n")


def write_library_sizes(out_path, stats_by_sample, samples):
    with open(out_path, "w") as out:
        out.write(
            "sample\tunit\treads_processed\treads_mapped_to_known_clades"
            "\treads_unclassified\tfraction_mapped\n"
        )
        for sample in samples:
            stats = stats_by_sample[sample]
            processed = stats["reads_processed"]
            mapped = stats["reads_mapped"]
            unclassified = max(processed - mapped, 0)
            fraction = f"{mapped / processed:.6f}" if processed else "NA"
            out.write(
                f"{sample}\t{stats['unit']}\t{processed}\t{mapped}"
                f"\t{unclassified}\t{fraction}\n"
            )


def build(profiles, counts_out, species_out, library_out):
    for path in (counts_out, species_out, library_out):
        directory = os.path.dirname(path)
        if directory:
            os.makedirs(directory, exist_ok=True)

    samples, per_sample, stats_by_sample = [], {}, {}
    taxids, all_clades = {}, set()

    for path in profiles:
        sample = sample_name(path)
        if not os.path.exists(path):
            print(f"WARNING: {path} not found; {sample} written as zeros",
                  file=sys.stderr)
            samples.append(sample)
            per_sample[sample] = {}
            stats_by_sample[sample] = {
                "reads_processed": 0, "reads_mapped": 0, "unit": "reads"}
            continue

        counts, sample_taxids, stats = parse_profile(path)
        samples.append(sample)
        per_sample[sample] = counts
        stats_by_sample[sample] = stats
        taxids.update(sample_taxids)
        all_clades.update(counts)

    # UNCLASSIFIED first, then clades shallowest-to-deepest and alphabetical,
    # so kingdom rows precede the species nested under them.
    clades = sorted(all_clades, key=lambda c: (c != "UNCLASSIFIED", c.count("|"), c))

    write_counts(counts_out, clades, taxids, per_sample, samples)
    write_counts(species_out, clades, taxids, per_sample, samples, species_only=True)
    write_library_sizes(library_out, stats_by_sample, samples)

    species = sum(1 for c in clades if "s__" in c)
    print(f"Merged {len(samples)} profile(s): {len(clades)} clades, "
          f"{species} with a species level")
    return len(samples)


# -- Snakemake entry point ---------------------------------------------------
try:
    snakemake  # noqa: F821 - injected by Snakemake at runtime

    # Snakemake does not redirect a script's output into {log} the way it does
    # for a shell block, so do it here rather than leave an empty log file.
    _log = snakemake.log[0] if snakemake.log else None
    if _log:
        _dir = os.path.dirname(_log)
        if _dir:
            os.makedirs(_dir, exist_ok=True)
        sys.stdout = sys.stderr = open(_log, "w")

    build(
        list(snakemake.input.profiles),
        snakemake.output.counts,
        snakemake.output.species,
        snakemake.output.library_sizes,
    )

except NameError:
    import argparse

    parser = argparse.ArgumentParser(
        description="Merge MetaPhlAn profiles into read-count tables")
    parser.add_argument("--profiles", nargs="+", required=True,
                        help="MetaPhlAn *_profile.txt files")
    parser.add_argument("--counts", required=True, help="All-clade count table")
    parser.add_argument("--species", required=True, help="Species-level count table")
    parser.add_argument("--library-sizes", required=True,
                        help="Per-sample library size table")
    args = parser.parse_args()

    build(args.profiles, args.counts, args.species, args.library_sizes)
