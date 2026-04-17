# Taxonomic Classification in OpusTaxa

## What is Taxonomic Classification?

Taxonomic classification is the process of determining which organisms are present in a biological sample and in what proportions. In shotgun metagenomics, a sample (e.g. a stool, soil, or water specimen) is sequenced directly without culturing, generating millions of short DNA reads from all organisms present simultaneously. Taxonomic classification assigns each read — or a representative subset of reads — to a known taxon (species, genus, family, etc.) by comparing it to a reference database of known genomes.

The output is a **microbial community profile**: a table describing which organisms were detected and their relative (or absolute) abundances. These profiles are the foundation for downstream analyses such as alpha/beta diversity, differential abundance testing, and community-level comparisons across samples or studies.

Accurate taxonomic profiling is technically challenging because:

- Reads are short (typically 150 bp) and may match many organisms
- Closely related species share highly conserved genomic regions
- Many microbial species lack complete reference genomes
- Different profiling tools use different algorithms, marker gene sets, and reference databases — meaning results can vary depending on the tool used

## The Multi-Tool Approach in OpusTaxa

A key design principle of OpusTaxa is the integration of **three independent taxonomic classifiers**. Running multiple tools on the same dataset serves as an internal validation strategy: findings that are consistent across tools with different underlying approaches and different reference databases are more likely to reflect genuine biological signal rather than tool-specific or database-specific artefacts.

Running multiple complementary tools on the same dataset can provide an internal sanity check, helping to distinguish stable biological signals from tool-specific artefacts.

The three tools we have selected are:

---

## MetaPhlAn 4

**MetaPhlAn** (Metagenomic Phylogenetic Analysis) is the **primary taxonomic profiler** in OpusTaxa. Results presented in OpusTaxa outputs are drawn from MetaPhlAn, and it is enabled by default.

### How it works

MetaPhlAn uses a curated set of **clade-specific marker genes** — unique genomic regions that are present in one taxon but absent (or highly divergent) in all others. Reads are aligned to this marker database (using Bowtie2), and abundance is estimated from the fraction of markers detected for each taxon.

### Database

MetaPhlAn 4 uses the **CHOCOPhlAn SGB (Species-level Genome Bins)** database, which spans bacteria, archaea, viruses, and eukaryotes. The Jan 2025 release used in OpusTaxa (`mpa_vJan25_CHOCOPhlAnSGB_202503`) includes both characterised and uncharacterised (novel) SGBs, enabling detection of organisms that lack a formal species name.

**Database size:** ~34 GB uncompressed

### Key properties

- Reports **relative abundances** (reads assigned to a taxon as a fraction of all classified reads)
- High **specificity** — marker-based approach minimises false positives
- Taxonomic framework rooted in **NCBI taxonomy**
- Enables downstream **strain-level analysis** via StrainPhlAn
- Tightly integrated with the **bioBakery ecosystem** (HUMAnN for functional profiling, MLP for microbial load prediction)
- One of the most widely used and benchmarked tools for human-associated microbiome studies

### Outputs produced by OpusTaxa

- Per-sample relative abundance profiles
- Merged cross-sample abundance table (all taxonomic levels)
- Bowtie2 alignment files (for StrainPhlAn if enabled)

---

## SingleM

**SingleM** is the **second taxonomic profiler** in OpusTaxa, enabled by default. It serves as an independent validation of MetaPhlAn results.

### How it works

SingleM identifies **highly conserved single-copy marker genes** (primarily ribosomal proteins and other universal prokaryotic markers) directly from metagenomic reads. Rather than aligning to whole-genome databases, it extracts reads that overlap these conserved windows and assigns them using an OTU (Operational Taxonomic Unit) approach against the **GTDB (Genome Taxonomy Database)**.

### Database

SingleM uses the **S5.4.0 GTDB r226 metapackage** (released March 2025), built on the GTDB taxonomy — a phylogenetically consistent, genome-based reclassification of bacteria and archaea.

**Database size:** ~7 GB

### Key properties

- Reports **OTU-level profiles** with coverage-based abundance estimates
- Uses **GTDB taxonomy** (differs from NCBI taxonomy used by MetaPhlAn)
- Specialised for **prokaryotes** (bacteria and archaea); estimates prokaryotic fraction of total reads
- More sensitive to novel or poorly characterised lineages due to universal marker approach
- Smaller database footprint relative to MetaPhlAn or Kraken2

### Outputs produced by OpusTaxa

- OTU tables per sample
- Species and genus-level aggregated abundance tables
- Prokaryotic fraction estimates (useful for quality assessment)
- Merged cross-sample tables at multiple taxonomic levels

---

## Kraken2 + Bracken

**Kraken2** with **Bracken** abundance re-estimation is the **third taxonomic classifier** in OpusTaxa. It is **disabled by default** but can be enabled in the configuration file for studies requiring orthogonal validation or k-mer-based classification.

### How it works

Kraken2 uses **exact k-mer matching** against a reference database of genomic sequences. Every k-mer (short substring) in each read is looked up in a hash table; the read is assigned to the lowest common ancestor of all matched taxa. Bracken then uses the Kraken2 report to re-estimate species-level abundances probabilistically, correcting for reads that were assigned above species level.

### Database

OpusTaxa uses the **PlusPF-16 database** (`k2_pluspf_16_GB_20251015`), which includes bacteria, archaea, viruses, fungi, plasmids, human, and protozoa sequences from RefSeq.

**Database size:** 16 GB

### Key properties

- **Extremely fast** — k-mer hashing enables classification of millions of reads per second
- **Broad taxonomic coverage** including fungi, viruses, and protozoa (beyond prokaryotes)
- Uses **NCBI RefSeq** as the reference — sensitive to database completeness
- Known to have **higher false positive rates** than marker-based tools in some benchmarks, particularly for organisms with large amounts of genomic sequence in the database
- Bracken dramatically improves species-level abundance estimates over raw Kraken2 output

### Outputs produced by OpusTaxa

- Per-sample Kraken2 classification reports
- Bracken-adjusted species-level abundance tables
- Merged cross-sample Bracken output

---

## Comparison of the Three Tools

| Feature | MetaPhlAn 4 | SingleM | Kraken2 + Bracken |
|---------|------------|---------|-------------------|
| **Algorithm** | Marker gene alignment (Bowtie2) | Single-copy gene OTUs | k-mer exact matching |
| **Reference database** | CHOCOPhlAn SGBs (NCBI taxonomy) | GTDB r226 | RefSeq PlusPF (NCBI taxonomy) |
| **Taxonomic framework** | NCBI | GTDB | NCBI |
| **Prokaryote focus** | Bacteria, archaea, viruses, eukaryotes | Primarily bacteria & archaea | Bacteria, archaea, viruses, fungi, protozoa |
| **Novel organism sensitivity** | High (SGBs for uncharacterised taxa) | High (universal markers) | Lower (requires genome in DB) |
| **Speed** | Moderate | Moderate | Very fast |
| **Database size** | ~34 GB | ~7 GB | ~16 GB |
| **Specificity** | High | High | Moderate |
| **Default in OpusTaxa** | Yes (primary output) | Yes | No (optional) |
| **Memory requirement** | ~50 GB | ~40 GB | ~64 GB |

---

## Why Run Multiple Tools?

Each tool makes different assumptions, uses different reference data, and follows a different algorithmic approach. A species that is misclassified or absent from one tool's database may be correctly identified by another. Conversely, false positives arising from database contamination or k-mer coincidence in one tool are unlikely to propagate to tools with completely different matching strategies.

**Concordant findings** across MetaPhlAn, SingleM, and Kraken2 provide strong evidence that a detected organism or community pattern is biologically real. **Discordant findings** highlight areas that warrant closer inspection — they may reflect genuine differences in database coverage, taxonomic frameworks (NCBI vs GTDB), or algorithmic sensitivity.

This multi-tool strategy is particularly valuable for:

- **Cross-study reproducibility**: Reporting MetaPhlAn results while providing SingleM and Kraken2 as validation layers allows other researchers to assess whether findings hold under alternative profiling strategies
- **Novel organisms**: SingleM's OTU approach and MetaPhlAn's SGB database both handle uncharacterised taxa that would be missed by a database restricted to named reference genomes
- **Fungal and protozoal content**: Kraken2's broader taxonomic coverage complements the prokaryotic focus of MetaPhlAn and SingleM

The primary outputs reported by OpusTaxa are from **MetaPhlAn**, which has the most extensive literature, benchmarking, and integration with downstream tools (HUMAnN, StrainPhlAn, MLP). SingleM and optionally Kraken2 are provided as independent validation layers.
