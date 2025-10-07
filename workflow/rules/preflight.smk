samples = list() #our list of SRA_IDs

with open(config["input"], "r") as fh:
    for line in fh:
            line = line.strip()
            if line:
                samples.append(line)

targets = dict()

targets["raw"] = expand(
    os.path.join(config["output"], "fastq_raw", "{sra_id}_{r}.fastq.gz"),
    sra_id = samples,
    r = ["1", "2"]
    )

targets["trimmed"] = expand(
    os.path.join(config["output"], "fastq_trimmed", "{sra_id}_{r}.fastq.gz"),
    sra_id = samples,
    r = ["1", "2"]
    )
