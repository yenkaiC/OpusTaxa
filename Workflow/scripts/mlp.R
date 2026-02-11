if (!requireNamespace("microbial.load.predictor", quietly = TRUE)) {
    remotes::install_github("grp-bork/microbial_load_predictor")
}

library(tidyverse)
library(microbial.load.predictor)  # devtools::install_github("grp-bork/microbial_load_predictor")

# Get args passed from Snakemake
input_profile <- snakemake@input[["profile"]]
output_load   <- snakemake@output[["load"]]
output_qmp    <- snakemake@output[["qmp"]]

# Read MetaPhlAn4 profile
input <- read.delim(input_profile, header = T, row.names = 1, check.names = F, comment.char = "#")

# Transpose - MLP expects samples as rows, species as columns
input <- data.frame(t(input), check.names = F)

# Predict microbial load using MetaPhlAn4 + GALAXY model
load <- MLP(input, "metaphlan4", "galaxy", "load")
qmp  <- MLP(input, "metaphlan4", "galaxy", "qmp")

# Write outputs
write.table(load, output_load, sep = "\t", quote = F, row.names = T)
write.table(qmp,  output_qmp,  sep = "\t", quote = F, row.names = T)