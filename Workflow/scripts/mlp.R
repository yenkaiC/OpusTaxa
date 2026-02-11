library(MLP)

library(microbial.load.predictor)

# Get args passed from Snakemake
input_profile <- snakemake@input[["profile"]] # → "Data/Metaphlan/sample_profile.txt"
output_load   <- snakemake@output[["load"]]   # → "Data/MLP/sample_load.tsv"
output_qmp    <- snakemake@output[["qmp"]]    # → "Data/MLP/sample_qmp.tsv"

# Read MetaPhlAn4 profile (skip comment lines starting with #)
input <- read.delim(input_profile, header = TRUE, row.names = 1, check.names = FALSE, comment.char = "#")

# Transpose - MLP expects samples as rows, species as columns
input <- data.frame(t(input), check.names = F)

# Predict microbial load using MetaPhlAn4 + GALAXY model
load <- MLP(input, "metaphlan4", "galaxy", "load")
qmp  <- MLP(input, "metaphlan4", "galaxy", "qmp")

# Write outputs
write.table(load, output_load, sep = "\t", quote = F, row.names = T)
write.table(qmp,  output_qmp,  sep = "\t", quote = F, row.names = T)