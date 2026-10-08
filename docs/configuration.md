# Configuring OpusTaxa

This page covers the three things most users need to change: **where the databases live**, **which tools run**, and **how many threads each tool gets**. It also covers tool parameters such as the Bracken read length or the NoHuman confidence score.

Nothing here requires editing the workflow code. Everything is either a line in `config/config.yaml` or a flag on the command line.


## Where settings live

| Location | What it controls | When to use it |
|----------|------------------|----------------|
| `config/config.yaml` | Database location, input/output directories, which tools run, threads per tool, tool parameters | Your normal settings — edit once, applies to every run |
| `--config key=value` on the command line | The same settings, for one run only | Trying something out, or a one-off run with different inputs |
| `config/slurm/config.yaml`, `config/slurm_singularity/config.yaml` | How Snakemake talks to SLURM: job limits, memory, runtime, partitions | Cluster settings, not tool settings |

Command line beats the config file. Anything you do not set on the command line keeps its value from `config/config.yaml`.

The SLURM profiles are a separate layer. They control how jobs are submitted, not what the tools do, so a database path never belongs there.

After any change, check it with a dry-run before committing to a real run:

```bash
snakemake --use-conda --dry-run --cores 1
```


## Database location

By default all databases go into a `Database/` folder inside your OpusTaxa directory:

```
Database/
├── nohuman/HPRC.r2/db/     # NoHuman (~5.9 GB)
├── metaphlan/              # MetaPhlAn (~34 GB)
├── singlem/                # SingleM (~10 GB)
├── kraken2/                # Kraken2 + Bracken (~16 GB)
├── humann/                 # HUMAnN (~52 GB)
├── card/                   # RGI / CARD (~16 GB)
├── antismash/              # antiSMASH (~9 GB)
└── sylph/                  # Sylph (~25 GB)
```

With every module enabled that is roughly 140 GB, so most people want it somewhere other than their home directory.

### Set it in the config file

Edit the first line of `config/config.yaml`:

```yaml
databaseDirectory: /scratch/your/directory/shared/OpusTaxa_DB
```

### Set it on the command line

```bash
snakemake --use-conda --cores 16 \
    --config databaseDirectory=/scratch/your/directory/shared/OpusTaxa_DB
```

Use an **absolute path**. A relative path such as `Database` is interpreted from wherever you launched Snakemake, so the same setting can point at different folders depending on where you are.

### Sharing one database between users

This is the main reason to move the databases. Databases are large and slow to download, and several people in a group rarely need their own copies.

1. One person downloads everything once into a group-readable location (see *Downloading databases ahead of time* below).
2. They make it readable for everyone else: `chmod -R g+rX /path/to/OpusTaxa_DB`.
3. Everyone points `databaseDirectory` at that folder.

OpusTaxa only downloads a database when it is missing, so the second person to run simply skips the download steps. The database inputs are marked `ancient()`, which means a database that is newer than someone's results does not cause their samples to be re-analysed.

Two things to watch:

- **Keep the shared folder off `/scratch` on Pawsey**, where files are purged after 21 days. Use `/software/projects/<project>/` instead.
- **Read-only is fine, but only for complete databases.** If a module's database is missing, that user's run will try to download it and fail on permissions. Have one person download every database the group uses.

### Downloading databases ahead of time

Useful on a cluster where downloads and analysis have different time limits, and required when you are populating a shared folder. Each database has its own rule:

```bash
snakemake --use-conda --cores 1 --config databaseDirectory=/path/to/shared_DB \
    --until dl_noHuman_DB
```

| Module | Rule name |
|--------|-----------|
| NoHuman | `dl_noHuman_DB` |
| MetaPhlAn | `dl_metaphlan_DB` |
| SingleM | `dl_singlem_DB` |
| Kraken2 / Bracken | `dl_kraken2_DB` |
| HUMAnN | `dl_humann_chocophlan`, `dl_humann_uniref`, `dl_humann_utility` |
| RGI (CARD) | `dl_card_DB` |
| antiSMASH | `antismash_download_databases` |
| geNomad | `dl_genomad_db` |
| Sylph | `dl_sylph_DB`, `dl_sylph_tax`, `dl_sylph_viral_DB` |

### If you use containers

Singularity can only see folders that are bind-mounted into the container. The bundled profile mounts `/scratch` and `/software`, so a shared database under either of those works as-is. Anywhere else, add it to `singularity-args` in `config/slurm_singularity/config.yaml`:

```yaml
singularity-args: "-B /scratch -B /software -B /data/databases --pwd $(pwd -P)"
```


## Turning tools on and off

Every module is a `true`/`false` flag. The defaults live in the `# Flags` block of `config/config.yaml`:

```yaml
metaphlan: false
singlem: false
kraken2: false
metaspades: false
humann: false
rgi: false
antismash: false
sylph: false
environmental: false
```

Change them there for a setting you always want, or pass them per run:

```bash
snakemake --use-conda --cores 16 \
    --config kraken2=true humann=true metaspades=true rgi=true
```

fastp, NoHuman, FastQC and MultiQC always run — they are the preprocessing backbone, and everything else depends on their output. The full list of flags is in [local.md](local.md) and [hpc.md](hpc.md).

Some modules depend on others. Anything contig-based (RGI, antiSMASH, Prodigal-gv, geNomad) needs `metaspades=true`, and Bracken comes with `kraken2=true`.


## Threads

Threads are per tool, per sample. A rule with 10 threads uses 10 cores for one sample, and Snakemake runs as many samples side by side as your `--cores` (local) or `jobs` (SLURM) setting allows.

### In the config file

Edit the `threads:` block in `config/config.yaml`:

```yaml
threads:
  fastp: 10
  nohuman: 8
  fastqc: 8
  metaphlan: 8
  singlem: 10
  kraken2: 8
  humann: 10
  metaspades: 20        # metaspades speed peaks at 32
  rgi: 10
  antismash: 16
  genomad: 8
  sylph: 10
```

Changing threads does not invalidate finished results, so you can tune this between runs freely.


## Tool parameters

Settings that change what a tool actually does live under `params:` in `config/config.yaml`, grouped by tool:

```yaml
params:
  bracken:
    read_length: 150           # -r, sequencing read length
    level: "S"                 # -l, S=species, G=genus, F=family

  antismash:
    taxon: "bacteria"          # bacteria or fungi
    genefinding_tool: "prodigal-m"

  rgi:
    alignment_tool: "DIAMOND"  # DIAMOND or BLAST
    include_loose: false

  nohuman:
    confidence: 0.0            # -C/--conf, Kraken2 minimum confidence (0-1)

  genomad:
    splits: 8
    min_score: 0.7
    min_number_genes: 1
```

## Other directories

Input and output locations follow the same pattern. The most commonly changed one is the input folder:

```bash
snakemake --use-conda --cores 16 --config inputFastQDirectory=/path/to/your/fastq
```

The rest are listed at the top of `config/config.yaml` (`nohumanDirectory`, `metaphlanDirectory`, `logDirectory` and so on) and rarely need changing.


## A worked example

A lab shares one database folder, runs on SLURM, wants Kraken2 and assembly, and has a node with plenty of cores:

```yaml
# config/config.yaml
databaseDirectory: /scratch/projects/mydirectory/OpusTaxa_DB

kraken2: true
metaspades: true

threads:
  metaspades: 32
  kraken2: 12

params:
  bracken:
    read_length: 150
```

```bash
snakemake --workflow-profile config/slurm --dry-run    # check
snakemake --workflow-profile config/slurm              # run
```

Someone doing a one-off run on a different input set, without touching the shared config:

```bash
snakemake --workflow-profile config/slurm \
    --config inputFastQDirectory=/scratch/projects/secret_data/fastq \
             databaseDirectory=/scratch/projects/secret_database/OpusTaxa_DB \
             metaphlan=true
```


## See also

- [Running locally](local.md)
- [Running on HPC / SLURM](hpc.md)
- [Running on Pawsey Setonix](pawsey.md)
- [What is Snakemake?](snakemake.md)
