---
layout: default
title: Modules
nav_order: 7
has_children: true
permalink: /modules
---

# Modules

OpusTaxa is built around independent, toggleable modules. The table below summarises all modules, their default state, dependencies, and resource requirements.

| Module | Default | Requires | Peak RAM | Approx. Time / sample |
|--------|---------|----------|----------|----------------------|
| [fastp]({% link modules/fastp.md %}) | Always on | — | 32 GB | 30 min |
| [NoHuman]({% link modules/nohuman.md %}) | Always on | fastp | 32 GB | 30 min |
| [QC]({% link modules/qc.md %}) | Always on | — | 12 GB | 15 min |
| [MetaPhlAn]({% link modules/metaphlan.md %}) | **On** | NoHuman | 50 GB | 2–4 h |
| [SingleM]({% link modules/singlem.md %}) | **On** | NoHuman | 40 GB | 4–8 h |
| [Kraken2]({% link modules/kraken2.md %}) | Off | NoHuman | 64 GB | 1–2 h |
| [MetaSPAdes]({% link modules/metaspades.md %}) | Off | NoHuman | 100 GB | 12–48 h |
| [HUMAnN]({% link modules/humann.md %}) | Off | MetaPhlAn | 64 GB | 8–23 h |
| [RGI]({% link modules/rgi.md %}) | Off | MetaSPAdes | 40 GB | 4–16 h |
| [AntiSMASH]({% link modules/antismash.md %}) | Off | MetaSPAdes | 32 GB | 12–48 h |
| [MLP]({% link modules/mlp.md %}) | Off | MetaPhlAn | 16 GB | < 1 h |
| [StrainPhlAn]({% link modules/strainphlan.md %}) | Off | MetaPhlAn | 32 GB | 1–4 h |
| [Prodigal-GV]({% link modules/prodigal-gv.md %}) | Off | MetaSPAdes | 32 GB | 2–10 h |

Enable modules via `--config` on the command line or by editing `config/config.yaml`. See [Configuration]({% link configuration.md %}) for details.
