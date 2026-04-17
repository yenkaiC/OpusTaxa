# What is Snakemake?

Snakemake is the workflow management system that OpusTaxa is built on. You don't need to be familiar with Snakemake to use OpusTaxa, but understanding the basics will help you interpret what's happening when you run the pipeline.

## The core idea

A Snakemake pipeline is made up of **rules**. Each rule describes one step in an analysis — for example, trimming reads, running a classifier, or merging output tables. Each rule knows what files it needs as input and what files it will produce as output.

When you run Snakemake, it looks at the final outputs you want and works backwards to figure out which rules need to run and in what order. You never have to specify the order yourself.

## What this means in practice

- **It only runs what's needed.** If you've already run part of the pipeline and want to add a new tool, Snakemake will pick up where it left off rather than starting over.
- **It handles multiple samples automatically.** The same rules apply to every sample in your input folder without any extra configuration.
- **It manages software environments.** Each tool runs inside its own isolated conda environment, so you don't need to worry about software conflicts or manually installing dependencies.
- **It can run on a cluster.** On HPC systems, Snakemake submits each job to the scheduler (e.g. SLURM) automatically.

## Running OpusTaxa

Once you have downloaded OpusTaxa and placed your FASTQ files in the `Data/Raw_FastQ/` folder, navigate to the OpusTaxa directory and run:

```bash
cd /path/to/OpusTaxa
snakemake --use-conda --cores 16
```

Snakemake reads the `Snakefile` in that directory, which defines the entire pipeline. It then scans the `Data/Raw_FastQ/` folder for your samples, builds a list of all the outputs it needs to produce, and starts executing rules in the correct order. You will see each job logged to the terminal as it runs.

The `--use-conda` flag tells Snakemake to automatically create and use isolated software environments for each tool — you don't need to install MetaPhlAn, SingleM, or any other tool yourself. The `--cores` flag controls how many CPU cores Snakemake can use at once; set this to match your machine.

If something goes wrong, Snakemake will report which step failed and why. Once you've fixed the issue, re-running the same command will resume from the failed step — it will not re-run steps that already completed successfully.

## Further reading

For a deeper introduction to Snakemake, see the [official documentation](https://snakemake.readthedocs.io).
