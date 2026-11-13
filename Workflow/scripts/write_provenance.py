#!/usr/bin/env python3
"""
Write a provenance record for one OpusTaxa run.

Produces a plain-text file naming the OpusTaxa version, the version of every
tool that was enabled, and the version of every reference database that was
actually installed when the run was made. The intent is that this file, kept
alongside the results, is enough to write a methods section from and enough to
tell two runs apart months later.

Two different kinds of fact are reported, and the file says which is which:

  declared   what the workflow asked for - the conda pin in Workflow/envs/,
             the container tag in config.yaml, the database name hard-coded in
             the rule. Exact, but it describes intent.
  installed  what was found on disk in the database directory at the time of
             writing. This is the half that varies between users sharing a
             database, and the half worth checking when results disagree.

Standard library only, so no environment or container is needed.

Usage (standalone):
    python write_provenance.py --repo . --output Data/opustaxa_versions.txt \
        --database-dir Database

Usage (from Snakemake):
    Called via the script: directive; see rule write_provenance.
"""

import glob
import json
import os
import platform
import re
import subprocess
import sys
from datetime import datetime, timezone

# label, config flag (None = always runs), env yaml, package pinned in it, container key
TOOLS = [
    ("fastp",       None,           "fastp.yaml",       "fastp",        "fastp"),
    ("FastQC",      None,           "fastqc.yaml",      "fastqc",       "fastqc"),
    ("MultiQC",     None,           "multiqc.yaml",     "multiqc",      "multiqc"),
    ("NoHuman",     "nohuman",      "nohuman.yaml",     "nohuman",      "nohuman"),
    ("SRA tools",   "download_sra", "sra.yaml",         "sra-tools",    "sra"),
    ("Nonpareil",   "nonpareil",    "nonpareil.yaml",   "nonpareil",    "nonpareil"),
    ("MetaPhlAn",   "metaphlan",    "metaphlan.yaml",   "metaphlan",    "metaphlan"),
    ("StrainPhlAn", "strainphlan",  "metaphlan.yaml",   "metaphlan",    "metaphlan"),
    ("SingleM",     "singlem",      "singlem.yaml",     "singlem",      "singlem"),
    ("Kraken2",     "kraken2",      "kraken2.yaml",     "kraken2",      "kraken2"),
    ("Bracken",     "kraken2",      "kraken2.yaml",     "bracken",      "kraken2"),
    ("Sylph",       "sylph",        "sylph.yaml",       "sylph",        "sylph"),
    ("metaSPAdes",  "metaspades",   "spades.yaml",      "spades",       "metaspades"),
    ("HUMAnN",      "humann",       "humann.yaml",      "humann",       "humann"),
    ("RGI",         "rgi",          "rgi.yaml",         "rgi",          "rgi"),
    ("antiSMASH",   "antismash",    "antismash.yaml",   "antismash",    "antismash"),
    ("Prodigal-GV", "prodigal_gv",  "prodigal-gv.yaml", "prodigal-gv",  "prodigal_gv"),
    ("geNomad",     "genomad",      "genomad.yaml",     "genomad",      "genomad"),
    ("MLP",         "mlp",          "mlp.yaml",         "r-base",       "mlp"),
]

# A pinned dependency line: "- name=1.2.3" or, under pip:, "- name==1.2.3"
_PIN = re.compile(r"^\s*-\s*([A-Za-z0-9_.+-]+)\s*={1,2}\s*([^\s#]+)")


# -- helpers -----------------------------------------------------------------

def rule(title):
    return f"\n{'=' * 78}\n{title}\n{'=' * 78}\n"


def run_quietly(args, cwd=None):
    """Run a command, returning its stripped stdout or None."""
    try:
        out = subprocess.run(args, cwd=cwd, capture_output=True, text=True,
                             timeout=15, check=False)
    except (OSError, subprocess.SubprocessError):
        return None
    if out.returncode != 0:
        return None
    return out.stdout.strip() or None


def newest_mtime(path):
    try:
        return datetime.fromtimestamp(os.path.getmtime(path)).strftime("%Y-%m-%d")
    except OSError:
        return "unknown"


def subdirs(path):
    try:
        return sorted(d for d in os.listdir(path)
                      if os.path.isdir(os.path.join(path, d)))
    except OSError:
        return []


def dir_has_content(path):
    try:
        return bool(os.listdir(path))
    except OSError:
        return False


# -- OpusTaxa's own version --------------------------------------------------

def opustaxa_version(repo):
    """Prefer the git description; fall back to CITATION.cff."""
    described = run_quietly(
        ["git", "describe", "--tags", "--always", "--dirty"], cwd=repo)
    commit = run_quietly(["git", "rev-parse", "HEAD"], cwd=repo)
    branch = run_quietly(["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd=repo)

    cff_version = None
    cff = os.path.join(repo, "CITATION.cff")
    if os.path.exists(cff):
        try:
            with open(cff, encoding="utf-8") as handle:
                for line in handle:
                    match = re.match(r"^version:\s*['\"]?([^'\"\s]+)", line)
                    if match:
                        cff_version = match.group(1)
                        break
        except OSError:
            pass

    return {
        "version": cff_version or described or "unknown",
        "git_describe": described or "not a git checkout",
        "commit": commit or "unknown",
        "branch": branch or "unknown",
    }


# -- conda pins --------------------------------------------------------------

def read_pins(env_path):
    """Return {package: version} for every pinned dependency in an env yaml."""
    pins = {}
    try:
        with open(env_path, encoding="utf-8") as handle:
            for line in handle:
                if line.lstrip().startswith("#"):
                    continue
                match = _PIN.match(line)
                if match:
                    pins[match.group(1).lower()] = match.group(2)
    except OSError:
        pass
    return pins


# -- database inspection -----------------------------------------------------

def db_nohuman(db_dir, declared):
    root = os.path.join(db_dir, "nohuman")
    releases = subdirs(root)
    wanted = os.path.join(root, declared, "db")
    complete = all(os.path.exists(os.path.join(wanted, f"{n}.k2d"))
                   for n in ("hash", "opts", "taxo"))
    installed = (f"{declared} (complete)" if complete
                 else f"{declared} INCOMPLETE" if declared in releases
                 else "not installed")
    if releases and releases != [declared]:
        installed += f"; also present: {', '.join(r for r in releases if r != declared)}"
    return installed, wanted


def db_metaphlan(db_dir, declared):
    root = os.path.join(db_dir, "metaphlan")
    found = sorted({os.path.basename(p).split(".")[0]
                    for p in glob.glob(os.path.join(root, "mpa_*"))})
    if not found:
        return "not installed", root
    note = "" if declared in found else "  <-- configured index NOT among these"
    return ", ".join(found) + note, root


def db_singlem(db_dir, declared):
    root = os.path.join(db_dir, "singlem")
    found = subdirs(root)
    if not found:
        return "not installed", root
    note = "" if declared in found else "  <-- configured metapackage NOT among these"
    return ", ".join(found) + note, root


def db_kraken2(db_dir, declared):
    root = os.path.join(db_dir, "kraken2")
    if not os.path.exists(os.path.join(root, "hash.k2d")):
        return "not installed", root
    # The PlusPF tarballs are unversioned once unpacked; the build date is the
    # only identifier, so fall back to the index file's date.
    inspect = os.path.join(root, "inspect.txt")
    detail = ""
    if os.path.exists(inspect):
        try:
            with open(inspect, encoding="utf-8") as handle:
                first = handle.readline().strip()
            if first.startswith("#"):
                detail = f"; {first.lstrip('# ')}"
        except OSError:
            pass
    return f"{declared} (installed {newest_mtime(os.path.join(root, 'hash.k2d'))}){detail}", root


def db_humann(db_dir, declared):
    root = os.path.join(db_dir, "humann")
    parts = []
    for name in ("chocophlan", "uniref", "utility_mapping"):
        path = os.path.join(root, name)
        parts.append(f"{name}: " + ("present" if dir_has_content(path) else "MISSING"))
    return "; ".join(parts), root


def db_card(db_dir, declared):
    root = os.path.join(db_dir, "card")
    card_json = os.path.join(root, "card.json")
    if not os.path.exists(card_json):
        return "not installed", root
    # CARD has no versioned download URL, so the only record of which release
    # is installed is the _version field inside card.json.
    version = None
    try:
        with open(card_json, encoding="utf-8") as handle:
            data = json.load(handle)
        version = data.get("_version")
    except (OSError, ValueError, AttributeError):
        pass
    wildcard = os.path.join(root, "wildcard")
    extra = " + WildCARD variants" if dir_has_content(wildcard) else " (no WildCARD variants)"
    return f"CARD {version or 'version unreadable'}{extra}", root


def db_antismash(db_dir, declared):
    root = os.path.join(db_dir, "antismash")
    components = subdirs(root)
    if not components:
        return "not installed", root
    described = []
    for component in components:
        versions = subdirs(os.path.join(root, component))
        described.append(f"{component} {'/'.join(versions)}" if versions else component)
    # clusterblast is the component that silently half-installs: the downloader
    # judges it complete from proteins.fasta alone, so clusters.txt can be absent.
    missing = []
    for component in ("clusterblast", "knownclusterblast"):
        base = os.path.join(root, component)
        if not os.path.isdir(base):
            continue
        for found in [base] + [os.path.join(base, v) for v in subdirs(base)]:
            if os.path.exists(os.path.join(found, "proteins.fasta")) \
                    and not os.path.exists(os.path.join(found, "clusters.txt")):
                missing.append(os.path.relpath(found, root))
    result = ", ".join(described)
    if missing:
        result += f"  <-- INCOMPLETE, clusters.txt missing in: {', '.join(missing)}"
    return result, root


def db_genomad(db_dir, declared):
    root = os.path.join(db_dir, "genomad")
    version_file = os.path.join(root, "genomad_db", "version.txt")
    if not os.path.exists(version_file):
        return ("not installed" if not dir_has_content(root)
                else "present, version.txt missing"), root
    try:
        with open(version_file, encoding="utf-8") as handle:
            return f"genomad_db {handle.read().strip()}", root
    except OSError:
        return "present, version.txt unreadable", root


def db_sylph(db_dir, declared):
    root = os.path.join(db_dir, "sylph")
    sketches = sorted(os.path.basename(p) for p in glob.glob(os.path.join(root, "*.syldb")))
    tax = subdirs(os.path.join(root, "sylph-tax"))
    if not sketches and not tax:
        return "not installed", root
    parts = []
    if sketches:
        parts.append("databases: " + ", ".join(sketches))
    if tax:
        parts.append("taxonomy: " + ", ".join(tax))
    elif os.path.exists(os.path.join(root, "sylph-tax")):
        parts.append("taxonomy: present")
    return "; ".join(parts), root


# name, flag that enables it, declared-key, inspector
DATABASES = [
    ("NoHuman (host removal)",       "nohuman",     "nohuman",      db_nohuman),
    ("MetaPhlAn (ChocoPhlAn SGB)",   "metaphlan",   "metaphlan",    db_metaphlan),
    ("SingleM (metapackage)",        "singlem",     "singlem",      db_singlem),
    ("Kraken2 / Bracken",            "kraken2",     "kraken2",      db_kraken2),
    ("HUMAnN",                       "humann",      "humann",       db_humann),
    ("CARD (RGI)",                   "rgi",         "card",         db_card),
    ("antiSMASH",                    "antismash",   "antismash",    db_antismash),
    ("geNomad",                      "genomad",     "genomad",      db_genomad),
    ("Sylph",                        "sylph",       "sylph",        db_sylph),
]


# -- the report --------------------------------------------------------------

def build(repo, output, db_dir, enabled, declared, containers, settings,
          samples, deployment):
    directory = os.path.dirname(output)
    if directory:
        os.makedirs(directory, exist_ok=True)

    version = opustaxa_version(repo)
    now = datetime.now(timezone.utc).astimezone()
    lines = []
    add = lines.append

    add("OpusTaxa run provenance")
    add("=" * 78)
    add("")
    add("Versions of the pipeline, the tools and the reference databases used to")
    add("produce the results in this directory. Generated automatically; do not edit.")
    add("")
    add(f"  OpusTaxa version   : {version['version']}")
    add(f"  Git describe       : {version['git_describe']}")
    add(f"  Git commit         : {version['commit']}")
    add(f"  Git branch         : {version['branch']}")
    add(f"  Written            : {now.strftime('%Y-%m-%d %H:%M:%S %Z')}")
    add(f"  Host               : {platform.node()}")
    add(f"  Run directory      : {os.path.abspath(os.getcwd())}")
    add(f"  Workflow directory : {os.path.abspath(repo)}")
    add(f"  Database directory : {os.path.abspath(db_dir)}")
    add(f"  Software source    : {deployment}")
    add(f"  Snakemake          : {settings.get('snakemake_version', 'unknown')}")
    add(f"  Python             : {platform.python_version()} ({platform.platform()})")

    add(rule("RUN SETTINGS").rstrip("\n"))
    add("")
    add(f"  Samples ({len(samples)}): " + (
        ", ".join(samples) if len(samples) <= 12
        else ", ".join(samples[:12]) + f", ... (+{len(samples) - 12} more)"))
    add("")
    for key, value in settings.items():
        if key == "snakemake_version":
            continue
        add(f"  {key:<24}: {value}")
    add("")
    add("  Modules enabled : " + (
        ", ".join(sorted(k for k, v in enabled.items() if v)) or "none"))
    add("  Modules disabled: " + (
        ", ".join(sorted(k for k, v in enabled.items() if not v)) or "none"))

    add(rule("TOOLS").rstrip("\n"))
    add("")
    add("Versions are the pins declared in Workflow/envs/*.yaml. When the run used")
    add("containers, the image tag is the authoritative record of what executed and")
    add("the pin is what the image was built to contain.")
    add("")
    add(f"  {'Tool':<14} {'Version':<12} {'Image / conda environment'}")
    add(f"  {'-' * 14} {'-' * 12} {'-' * 44}")

    skipped = []
    for label, flag, env_file, package, container_key in TOOLS:
        if flag is not None and not enabled.get(flag, False):
            skipped.append(label)
            continue
        pins = read_pins(os.path.join(repo, "Workflow", "envs", env_file))
        version_text = pins.get((package or "").lower(), "unpinned")
        source = containers.get(container_key) if deployment.startswith("container") \
            else f"Workflow/envs/{env_file}"
        add(f"  {label:<14} {version_text:<12} {source or 'no container configured'}")
    if skipped:
        add("")
        add("  Not run in this analysis: " + ", ".join(skipped))

    add(rule("REFERENCE DATABASES").rstrip("\n"))
    add("")
    add("'Configured' is what the workflow asked for; 'Installed' is what was found")
    add("in the database directory when this file was written.")
    add("")

    any_db = False
    for name, flag, key, inspector in DATABASES:
        if not enabled.get(flag, False):
            continue
        any_db = True
        want = declared.get(key, "-")
        try:
            found, path = inspector(db_dir, want)
        except Exception as exc:                      # never fail a run over this
            found, path = f"could not be inspected ({exc})", os.path.join(db_dir, key)
        add(f"  {name}")
        add(f"      Configured : {want}")
        add(f"      Installed  : {found}")
        add(f"      Path       : {os.path.abspath(path)}")
        add("")
    if not any_db:
        add("  No database-backed module was enabled in this run.")
        add("")

    while lines and lines[-1] == "":
        lines.pop()
    add(rule("CITATION").rstrip("\n"))
    add("")
    add("  Every tool and database above is distributed by a third party under its")
    add("  own licence and citation terms. Cite the databases as well as the tools.")
    add("  For OpusTaxa itself, see CITATION.cff in the workflow directory.")
    add("")

    with open(output, "w", encoding="utf-8") as handle:
        handle.write("\n".join(lines) + "\n")

    print(f"Wrote provenance record to {output}")
    return output


# -- Snakemake entry point ---------------------------------------------------
try:
    snakemake  # noqa: F821 - injected by Snakemake at runtime

    _log = snakemake.log[0] if snakemake.log else None
    if _log:
        _dir = os.path.dirname(_log)
        if _dir:
            os.makedirs(_dir, exist_ok=True)
        sys.stdout = sys.stderr = open(_log, "w")

    build(
        repo=snakemake.params.repo,
        output=snakemake.output.versions,
        db_dir=snakemake.params.db_dir,
        enabled=dict(snakemake.params.enabled),
        declared=dict(snakemake.params.declared),
        containers=dict(snakemake.params.containers),
        settings=dict(snakemake.params.settings),
        samples=list(snakemake.params.samples),
        deployment=snakemake.params.deployment,
    )

except NameError:
    import argparse

    parser = argparse.ArgumentParser(
        description="Write an OpusTaxa provenance record")
    parser.add_argument("--repo", default=".", help="Workflow directory")
    parser.add_argument("--output", required=True, help="Output .txt path")
    parser.add_argument("--database-dir", required=True, help="Database directory")
    args = parser.parse_args()

    build(
        repo=args.repo,
        output=args.output,
        db_dir=args.database_dir,
        enabled={flag: True for flag in
                 [f for _, f, _, _, _ in TOOLS if f] + [f for _, f, _, _ in DATABASES]},
        declared={},
        containers={},
        settings={"note": "standalone run, configuration not recorded"},
        samples=[],
        deployment="conda (Workflow/envs)",
    )
