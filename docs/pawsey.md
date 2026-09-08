# Running OpusTaxa on Pawsey (Setonix) — A Beginner's Guide

This is a step-by-step walkthrough for running OpusTaxa on **Pawsey's Setonix** supercomputer. It assumes you have a Pawsey account and can log in via SSH, but assumes **no prior Snakemake, SLURM, or HPC experience**.

For the general (non-Pawsey) SLURM guide, see [hpc.md](hpc.md).

> **Setonix in one paragraph:** Setonix is a SLURM-managed cluster with a Lustre parallel filesystem. It has three important storage locations — `$HOME` (tiny, for config files only), `$MYSOFTWARE` (for software you install), and `$MYSCRATCH` (large, temporary, auto-purged after 21 days of inactivity). Setonix strongly prefers **Singularity/Apptainer containers** over conda because conda creates tens of thousands of small files that overwhelm Lustre. This guide uses containers as the default path.

---

## Understanding Setonix storage (read this first)

| Location | Variable | Use it for | Do **not** use it for |
|----------|----------|-----------|-----------------------|
| Home | `$HOME` | SSH keys, small config files | Anything large — the quota is very small |
| Software | `$MYSOFTWARE` | Miniconda **only** | Raw sequencing data, the OpusTaxa repo |
| Scratch | `$MYSCRATCH` | The OpusTaxa repo, input FASTQ, databases, all pipeline output | Long-term storage — files are **auto-deleted** after 21 days |

Two rules to remember: install **conda into `$MYSOFTWARE`** (installing into `$HOME` hits the quota — the number-one Setonix mistake), and **clone OpusTaxa and keep all your data on `$MYSCRATCH`**.

---

## Step 1 — Log in and go to your software directory

```bash
# From your own machine
ssh yourusername@setonix.pawsey.org.au
```

---

## Step 2 — Install conda (into `$MYSOFTWARE`)

**Conda must go in `$MYSOFTWARE`, not `$HOME`** — your home quota is too small to hold a conda installation.

```bash
cd $MYSOFTWARE

# Download the Miniconda installer
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh

# Run it, telling it to install INTO $MYSOFTWARE
bash Miniconda3-latest-Linux-x86_64.sh -b -p $MYSOFTWARE/miniconda3

# Activate conda for this session
source $MYSOFTWARE/miniconda3/etc/profile.d/conda.sh

# (Optional) make conda available every time you log in
conda init
```

> **Tip:** After `conda init`, log out and back in (or run `source ~/.bashrc`) so the `conda` command is available automatically.

---

## Step 3 — Standard installation of OpusTaxa

```bash
# Clone into scratch, NOT $MYSOFTWARE (you can create your folders/directories here)
cd $MYSCRATCH

# 1. Clone the OpusTaxa repository
git clone https://github.com/yenkaiC/OpusTaxa.git
cd OpusTaxa

# 2. Create and activate the Snakemake environment
conda create -n snakemake -c conda-forge -c bioconda snakemake
conda activate snakemake

# 3. Install the SLURM executor plugin
#    (this is what lets Snakemake submit jobs to SLURM for you)
pip install snakemake-executor-plugin-slurm
```

---
## Step 4 — Specify your Pawsey project

Every SLURM job must be charged to a project allocation. Setonix won't run your jobs until you tell it which project code to bill. Your project code looks like `pawseyXXXX` (e.g. `pawsey1234`) — it's the same code that appears in your `$MYSCRATCH` path (`/scratch/pawseyXXXX/yourusername`).

Open the SLURM profile config and set your account:

```bash
nano config/slurm_singularity/config.yaml
```

Find the `slurm_account` line under `default-resources` and replace the placeholder with your project code:

```yaml
default-resources:
  - "slurm_account=pawseyXXXX"     # <-- change to YOUR project code
  - "slurm_partition=work"
  ...
```

> **How to find your project code** if you're unsure: run `echo $MYSCRATCH` — the `pawseyXXXX` part of the path is your project. Or run `sacctmgr show assoc user=$(whoami) format=account%20` to list the projects you can charge to.

> **Why this matters:** if the account is wrong or left as someone else's code, your jobs will either be rejected at submission or silently charged to the wrong allocation.

---

## Step 5 — Start a persistent `screen` session

Snakemake must keep running on the **login node** for the whole job — it submits and monitors SLURM jobs on your behalf. If your SSH connection drops, Snakemake dies with it. A `screen` session keeps it alive.

```bash
# Start a named screen session
screen -S opustaxa

# Inside the session, re-activate your environment
conda activate snakemake

# Detach at any time: press Ctrl+A, then D <-- Remember!
# Reattach later:     screen -r opustaxa
```
> **Create the session once, then reattach — don't re-create it.** Run `screen -S opustaxa` only the *first* time. To get back into it later, always use `screen -r opustaxa`. If you run `screen -S opustaxa` again, you'll start a **second, empty** session instead of returning to your running pipeline, and `screen -r` will then complain there are multiple sessions to choose from. If you're ever unsure whether you already have one, run `screen -ls` to list your sessions before creating a new one.

> **Never** submit Snakemake itself as an `sbatch` job. It is the orchestrator — it needs to stay on the login node.

---

## Step 6 — Load the Singularity module

Setonix provides Singularity as a module. Load the SLURM-aware build:

```bash
module load singularity/4.1.0-slurm
```

> If that exact version has changed, list what's available with:
> `module avail 2>&1 | grep -i singularity`

---

## Step 7 — Dry-run with the singularity profile

A dry-run shows you every step Snakemake *would* run, without actually running anything. Always do this first to confirm your setup is correct.

```bash
cd $MYSCRATCH/OpusTaxa

snakemake --workflow-profile config/slurm_singularity --dry-run
```

If this prints a list of jobs and ends without errors, you are ready to run.

---

## Step 8 — Full run with module toggles

Once the dry-run looks good, drop the `--dry-run` flag to launch for real. All optional modules are switched on/off with `--config` flags — add as many as you need to the same command.

```bash
# Simplest full run (fastp, NoHuman, QC only)
snakemake --workflow-profile config/slurm_singularity

# Download SRA accessions listed in sra_id.txt, then run
snakemake --workflow-profile config/slurm_singularity --config download_sra=true

# Turn on additional modules
snakemake --workflow-profile config/slurm_singularity \
    --config kraken2=true humann=true metaspades=true rgi=true antismash=true prodigal_gv=true nonpareil=true

# Point at input FASTQ living on scratch
snakemake --workflow-profile config/slurm_singularity \
    --config inputFastQDirectory=$MYSCRATCH/myproject/fastq

# remember that /scratch has a 21 day deletion policy
```

### Common toggles

| What you want | Flag to add |
|---------------|-------------|
| Download SRA data | `download_sra=true` |
| Kraken2 + Bracken | `kraken2=true` |
| MetaSPAdes assembly | `metaspades=true` |
| HUMAnN functional profiling | `humann=true` |
| Resistance genes (RGI/CARD) | `rgi=true` |
| antiSMASH | `antismash=true` |
| Turn MetaPhlAn on | `metaphlan=true` |

> **Bind mounts:** `config/slurm_singularity/config.yaml` binds `/scratch` and `/software` into each container. On Setonix these map to your `$MYSCRATCH` and `$MYSOFTWARE` — the defaults should work, but if a job can't see your data, check the `singularity-args` bind paths (see [hpc.md](hpc.md#adjusting-containers-for-your-hpc)).

---

## Step 9 — Detach and let it run

With everything launched inside `screen`, detach and log off safely:

```
Press Ctrl+A, then D
```

Come back any time to check progress:

```bash
screen -r opustaxa       # reattach
squeue -u $(whoami)      # see your queued/running SLURM jobs
```

---

## Quick reference — the whole thing

```bash
ssh yourusername@setonix.pawsey.org.au
source $MYSOFTWARE/miniconda3/etc/profile.d/conda.sh   # if not auto-loaded
cd $MYSCRATCH/OpusTaxa

screen -S opustaxa        # FIRST time only — afterwards use: screen -r opustaxa
conda activate snakemake
module load singularity/4.1.0-slurm

snakemake --workflow-profile config/slurm_singularity --dry-run     # check
snakemake --workflow-profile config/slurm_singularity               # run
# Ctrl+A, D to detach
```

---

## Troubleshooting

- **`Disk quota exceeded` during conda install** → you installed into `$HOME`. Remove it and reinstall into `$MYSOFTWARE`.
- **Jobs can't find input data** → check the `-B` bind mounts in `config/slurm_singularity/config.yaml` point at your scratch path.
- **Snakemake stopped when SSH dropped** → you weren't inside `screen`. Restart it inside a `screen` session.
- **`module: command not found` / singularity version missing** → run `module avail 2>&1 | grep -i singularity` to find the current build name.
- **Databases won't download on compute nodes** → some nodes lack internet. Download on the login node first (see the Database Downloads section in [hpc.md](hpc.md)).
