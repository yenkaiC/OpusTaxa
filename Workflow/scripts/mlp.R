library(MLP)

# Get arguments from Snakemake
input_profile <- snakemake@input[["profile"]]
output_load   <- snakemake@output[["load"]]
output_qmp    <- snakemake@output[["qmp"]]

# Resolve paths
input_profile <- normalizePath(input_profile, mustWork = TRUE)
output_load   <- normalizePath(output_load, mustWork = FALSE)
output_qmp    <- normalizePath(output_qmp, mustWork = FALSE)

# Read MetaPhlAn profile
input <- read.delim(input_profile, header = TRUE, row.names = 1, 
                    check.names = FALSE, comment.char = "#")

# Transpose - MLP expects samples as rows, species as columns
input <- data.frame(t(input), check.names = FALSE)

cat("Input data dimensions:", nrow(input), "samples x", ncol(input), "species\n")

# Predict microbial load using the MLP function
# Correct arguments based on documentation:
# - profiler: "metaphlan4.mpa_vJan25_CHOCOPhlAnSGB_202503" (note the dot after metaphlan4)
# - training_data: "galaxy" (default, but "metacardis" is also available)
# Based on our experience with antibiotic samples, galaxy works better
# But if one is working on the effects of drugs, metacardis may work better in such circumstance
# - output: "load" or "qmp"

# Try with galaxy training data first (since that's what the models are named)
load_pred <- MLP(input, 
                 profiler = "metaphlan4.mpa_vJan25_CHOCOPhlAnSGB_202503", 
                 training_data = "galaxy", 
                 output = "load")

qmp_pred <- MLP(input, 
                profiler = "metaphlan4.mpa_vJan25_CHOCOPhlAnSGB_202503", 
                training_data = "galaxy", 
                output = "qmp")

# Format output
# MLP function returns a vector or data frame
if (is.data.frame(load_pred)) {
  load_out <- load_pred
} else {
  load_out <- data.frame(sample = rownames(input), load = load_pred)
}

if (is.data.frame(qmp_pred)) {
  qmp_out <- qmp_pred
} else {
  qmp_out <- data.frame(sample = rownames(input), qmp = qmp_pred)
}

# Write outputs
write.table(load_out, output_load, sep = "\t", quote = FALSE, row.names = FALSE)
write.table(qmp_out, output_qmp, sep = "\t", quote = FALSE, row.names = FALSE)

cat("MLP prediction complete!\n")