library(MLP)

# Get arguments passed from Snakemake
input_profile <- snakemake@input[["profile"]] # → "Data/Metaphlan/sample_profile.txt"
output_load   <- snakemake@output[["load"]]   # → "Data/MLP/sample_load.tsv"
output_qmp    <- snakemake@output[["qmp"]]    # → "Data/MLP/sample_qmp.tsv"

# Resolve to absolute paths before changing working directory
input_profile <- normalizePath(input_profile, mustWork = TRUE)
output_load   <- normalizePath(output_load,   mustWork = FALSE)
output_qmp    <- normalizePath(output_qmp,    mustWork = FALSE)

# Explicitly locate model files from extdata
pkg_extdata <- system.file("extdata", package = "MLP")
model_path  <- file.path(pkg_extdata, "galaxy", "model.metaphlan4.mpa_vJan25_CHOCOPhlAnSGB_202503.rds")
model_path_tr <- file.path(pkg_extdata, "galaxy", "model.metaphlan4.mpa_vJan25_CHOCOPhlAnSGB_202503.tr.rds")

# Read MetaPhlAn4 profile (skip comment lines starting with #)
input <- read.delim(input_profile, header = TRUE, row.names = 1, check.names = FALSE, comment.char = "#")

# Transpose - MLP expects samples as rows, species as columns
input <- data.frame(t(input), check.names = F)

# Predict microbial load using MetaPhlAn4 + GALAXY model
# Load models directly and predict
model    <- readRDS(model_path)
model_tr <- readRDS(model_path_tr)

load <- predict(model,    newdata = input)
qmp  <- predict(model_tr, newdata = input)

load <- data.frame(sample = rownames(input), load = load)
qmp  <- data.frame(sample = rownames(input), qmp  = qmp)

# Write outputs
write.table(load, output_load, sep = "\t", quote = F, row.names = T)
write.table(qmp,  output_qmp,  sep = "\t", quote = F, row.names = T)