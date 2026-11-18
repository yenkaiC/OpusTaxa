# Taxonomic Classification in OpusTaxa

## What Is Taxonomic Classification?

A microbiome sample, such as stool, saliva, soil or water, contains DNA from hundreds or thousands of different microorganisms. In **shotgun metagenomics**, all of that DNA is sequenced at once, without culturing anything first. The result is millions of short DNA fragments called **reads**, each typically about 150 letters (base pairs) long, from a mixture of unknown organisms.

**Taxonomic classification** (also called **taxonomic profiling**) answers two questions about those reads:

1. **Who is there?** Which bacteria, archaea, viruses or fungi are present?
2. **How much of each?** What proportion of the community does each one make up?

To answer them, a profiler compares the reads against a **reference database** of known microbial DNA. A read that closely matches a known genome is taken as evidence that the organism is present.

The output is a **community profile**: a table of organisms and their **relative abundances**, the share of the community each one makes up. For example:

| Taxon | Sample A | Sample B |
|-------|----------|----------|
| *Bacteroides uniformis* | 12.4% | 3.1% |
| *Faecalibacterium prausnitzii* | 8.7% | 15.2% |
| *Escherichia coli* | 0.5% | 4.8% |
| … | … | … |

These tables are the starting point for most microbiome analyses. Examples include:

- **alpha diversity**: how many taxa a sample contains and how evenly they're spread
- **beta diversity**: how different two samples' communities are
- **differential abundance**: which taxa differ between groups, e.g. patients vs controls

Profiles can be reported at different **taxonomic ranks**, from broad to specific: phylum → class → order → family → genus → species. Species level gives the most detail but is also the hardest to get right.

### Why It's Harder Than It Sounds

- **Reads are short.** A 150 bp fragment may match several related organisms equally well.
- **Related species share DNA.** Closely related species can be nearly identical across much of their genome.
- **Reference databases are incomplete.** Many microbes, especially outside the human gut, have never been sequenced. Their reads may go unclassified or be assigned to the closest known relative.
- **Taxonomies disagree.** Two main naming systems are in use: **NCBI** and **GTDB** (the Genome Taxonomy Database). They sometimes name or group the same organisms differently.

Because each tool deals with these problems differently, **different tools can give noticeably different results on the same data.** This is why OpusTaxa runs more than one.

## Why OpusTaxa Runs Multiple Tools

Profilers generally work in one of two ways:

- **Marker-based** tools look only at a small set of carefully chosen genes, each characteristic of a particular group of organisms. This is fast and gives few false detections, but most of the reads are ignored.
- **Whole-genome** tools compare reads against entire reference genomes, usually by matching short DNA "words" called **k-mers**. This uses more of the data and tends to estimate abundances well, but can produce more spurious low-level detections.

A large benchmark of 20 classifiers (Ye et al., 2019) found that:

- **The reference database matters more than the algorithm.** Differences between the tools' databases explained more of the variation in performance than differences between their methods.
- **The two approaches have complementary strengths.** Whole-genome k-mer tools gave the most accurate abundance estimates. Marker-based tools reported very few false positives, but their abundance profiles differed noticeably from other approaches.
- **False positives vary enormously.** On a mock community of 20 known species, tools reported anywhere from tens to thousands of species that weren't there, almost all at very low abundance.
- **Real data are harder than benchmarks.** Performance dropped on real samples, which, unlike test data, have no known answer to check against.

OpusTaxa therefore runs several profilers that differ in **both their method and their reference database**. A result that holds up across all of them is unlikely to be an artefact of any one tool. A result seen in only one is a cue to look more closely.

## The Tools at a Glance

| | MetaPhlAn 4 | SingleM | Kraken2 + Bracken | Sylph |
|-|-------------|---------|-------------------|-------|
| **Approach** | Marker-based (clade-specific genes) | Marker-based (universal single-copy genes) | Whole-genome (exact k-mer matching) | Whole-genome (k-mer sketching) |
| **Database** | CHOCOPhlAn SGBs (Jan 2025) | GTDB r226 (S5.4.0) | RefSeq PlusPF-16 | GTDB r220 (+ optional UHGV viral) |
| **Taxonomy** | NCBI | GTDB | NCBI | GTDB |
| **Organisms** | Bacteria, archaea, viruses, eukaryotes | Bacteria, archaea | Bacteria, archaea, viruses, fungi, protozoa | Bacteria, archaea (+ viruses with UHGV) |
| **Main strength** | Specificity; links to HUMAnN, StrainPhlAn, MLP | Novel prokaryotic lineages | Broadest coverage; abundance accuracy | Speed; species-level abundance |
| **Enabled by default** | Yes (primary output) | Yes | No | No |
| **Config flag** | `metaphlan` | `singlem` | `kraken2` | `sylph`, `sylph_viral` |

## MetaPhlAn 4 (primary profiler)

**How it works:** MetaPhlAn uses a curated set of **marker genes**, each found in one group of organisms and nowhere else. Reads are aligned to these markers with Bowtie2. Abundance is estimated from how much of each organism's marker set is covered.

**Database:** The CHOCOPhlAn database is organised into **SGBs (species-level genome bins)**. These include many uncharacterised species that don't yet have a formal name.

**Why it's the primary output:** MetaPhlAn has very few false positives and is one of the most widely used and benchmarked profilers. It also feeds directly into other OpusTaxa modules: HUMAnN (functional profiling), StrainPhlAn (strain-level analysis) and MLP (microbial load).

**Keep in mind:** Abundance estimates from marker-based tools can differ from those of whole-genome tools. Where precise quantification matters, cross-check them against Bracken or Sylph.

**Outputs:** Per-sample profiles, merged tables across samples (all ranks and species-only), and alignment files for StrainPhlAn.

## SingleM (marker-based check)

**How it works:** SingleM looks at a small set of **universal single-copy genes**, mainly ribosomal proteins found once in nearly every bacterium and archaeon. Reads covering these genes are grouped into OTUs (operational taxonomic units) and assigned taxonomy using GTDB.

**Why it's included:** Because it relies on universal genes rather than a catalogue of known species, SingleM is good at detecting **novel or poorly characterised prokaryotes**. It also estimates the **prokaryotic fraction** of each sample, the share of reads from bacteria and archaea, which is a useful quality check.

**Keep in mind:** It covers bacteria and archaea only, and uses GTDB names, which won't always match MetaPhlAn's NCBI names.

**Outputs:** Per-sample OTU tables and profiles, merged tables at multiple ranks, and prokaryotic fraction estimates.

## Kraken2 + Bracken (broad whole-genome classifier)

**How it works:** Kraken2 breaks each read into k-mers and looks them up in a database built from whole genomes. The read is assigned to the most specific taxon consistent with all its matches. Many reads can only be placed at genus level or above, so **Bracken** re-estimates abundances at species level.

**Why it's included:** It is the only profiler here whose database covers **fungi and protozoa** as well as bacteria, archaea and viruses. Whole-genome k-mer tools also gave some of the most accurate abundance estimates in benchmarking.

**Keep in mind:** Raw Kraken2 output can contain many low-abundance false positives. With Bracken and an abundance threshold, the benchmark found false-positive counts comparable to marker-based tools. Kraken2 only detects organisms with a genome in its database.

**Outputs:** Per-sample Kraken2 reports, Bracken species abundances, and a merged Bracken table.

## Sylph (fast whole-genome profiler)

**How it works:** Sylph first compresses each sample's reads into a compact **sketch**, a small sample of its k-mers. It then compares the sketch against sketches of reference genomes. From this it estimates which genomes are present, how similar the sample's strains are to them (**ANI**, average nucleotide identity) and at what abundance.

**Why it's included:** Like Kraken2, Sylph compares reads against whole genomes rather than marker genes. Unlike Kraken2, it uses GTDB, which gives a second whole-genome view whose names match SingleM's directly. It is very fast, and sketches are saved, so a sample can be re-profiled against another database without reprocessing its reads. The optional UHGV database (`sylph_viral`) adds **gut virus** profiling.

**Keep in mind:** The default database covers bacteria and archaea only. Sylph was published after the Ye et al. benchmark and was not evaluated there.

**Outputs:** Per-sample taxonomic profiles and a merged abundance table, plus equivalent viral tables if enabled.

## Interpreting Results Across Tools

**When tools agree** on an organism or pattern, that is strong evidence it is real.

**When they disagree**, the cause is usually one of these:

- **Database coverage**: the organism is in one tool's reference database but missing from another's.
- **Naming**: GTDB (SingleM, Sylph) and NCBI (MetaPhlAn, Kraken2) sometimes name or group taxa differently. A mismatch may be a difference in names rather than in biology.
- **Organism type**: only Kraken2 detects fungi and protozoa. SingleM and Sylph (by default) only cover bacteria and archaea.
- **Low abundance**: a taxon reported by only one tool at very low abundance is the most likely false positive.

### Recommendations

- **Apply an abundance threshold** before comparing tools or running statistics. Most false positives sit at very low relative abundance.
- **Compare at genus level** as well as species level. Tools agree more at genus level, and naming differences between taxonomies matter less.
- **When tools disagree, trust marker-based tools on presence and whole-genome tools on abundance.**
- **Include negative controls**, such as extraction blanks, where possible, and run them through the same pipeline.

Human DNA is removed with **NoHuman** before any profiling. Otherwise human reads are misclassified as microbial at measurable rates, as the benchmark found.

**A note on the evidence:** The benchmark tested earlier versions of these tools and databases (e.g. MetaPhlAn 2), so its exact figures may not apply to the versions used in OpusTaxa. Its general conclusions are the basis for OpusTaxa's design.

## Reference

Ye SH, Siddle KJ, Park DJ, Sabeti PC. (2019). Benchmarking metagenomics tools for taxonomic classification. *Cell* 178(4):779–794. https://doi.org/10.1016/j.cell.2019.07.010
