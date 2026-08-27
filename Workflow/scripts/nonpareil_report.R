#!/usr/bin/env Rscript
# ---------------------------------------------------------------------------
# nonpareil_report.R
#
# Reads all per-sample Nonpareil .npo files, fits the redundancy model to each,
# and produces:
#   1. A merged summary table (one row per sample) with the key metrics:
#      - coverage      : estimated fraction of the community sequenced (0-1)
#      - LR            : actual sequencing effort (bp)
#      - LRstar        : effort required for "nearly complete" coverage (~95%)
#      - modelR        : model fit (R^2)
#      - diversity     : Nonpareil sequence diversity index (Nd)
#   2. A single merged coverage-curve plot (all samples overlaid).
#
# Usage:
#   Rscript nonpareil_report.R <out_tsv> <out_pdf> <sample1.npo> [sample2.npo ...]
#
# The sample name is taken from the .npo filename (strips the .npo suffix).
# ---------------------------------------------------------------------------

suppressPackageStartupMessages(library(Nonpareil))

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 3) {
  stop("Usage: Rscript nonpareil_report.R <out_tsv> <out_pdf> <file1.npo> [file2.npo ...]")
}

out_tsv <- args[1]
out_pdf <- args[2]
npo_files <- args[-(1:2)]

labels <- sub("\\.npo$", "", basename(npo_files))

# Fit each curve without drawing (plot=FALSE), collect into a set for the plot.
dir.create(dirname(out_pdf), recursive = TRUE, showWarnings = FALSE)

pdf(out_pdf, width = 8, height = 6)
nps <- Nonpareil.set(
  npo_files,
  labels = labels,
  plot   = TRUE,
  plot.opts = list(plot.observed = TRUE)
)
invisible(dev.off())

# Pull the per-sample metrics out of the fitted set.
tab <- summary(nps)                       # matrix: rows = samples, cols = metrics
df  <- data.frame(sample = rownames(tab), tab, row.names = NULL,
                  check.names = FALSE)

dir.create(dirname(out_tsv), recursive = TRUE, showWarnings = FALSE)
write.table(df, file = out_tsv, sep = "\t", quote = FALSE, row.names = FALSE)

cat(sprintf("Wrote %d-sample Nonpareil summary to %s\n", nrow(df), out_tsv))
cat(sprintf("Wrote merged coverage-curve plot to %s\n", out_pdf))
