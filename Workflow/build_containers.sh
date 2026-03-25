#!/bin/bash
# ============================================================================
# build_containers.sh — Build all OpusTaxa Singularity containers
# ============================================================================
#
# Run this on a machine where you have sudo/fakeroot access (NOT on Setonix).
# Options: local workstation, Pawsey Nimbus VM, or any Linux box with
# Singularity/Apptainer installed.
#
# Usage:
#   bash build_containers.sh                    # Build all containers
#   bash build_containers.sh fastp nohuman      # Build specific containers only
#   bash build_containers.sh --fakeroot         # Build with --fakeroot (no sudo)
#
# After building, copy .sif files to Setonix:
#   scp containers/*.sif <user>@setonix.pawsey.org.au:/software/projects/<project>/<user>/containers/
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEF_DIR="${SCRIPT_DIR}/containers"
SIF_DIR="${SCRIPT_DIR}/containers"

# Parse --fakeroot flag
BUILD_FLAG=""
TOOLS=()
for arg in "$@"; do
    if [[ "$arg" == "--fakeroot" ]]; then
        BUILD_FLAG="--fakeroot"
    else
        TOOLS+=("$arg")
    fi
done

# All available tools
ALL_TOOLS=(
    fastp
    nohuman
    fastqc
    multiqc
    metaphlan
    singlem
    kraken2
    humann
    sra
    metaspades
    rgi
    antismash
    mlp
)

# If no tools specified, build all
if [[ ${#TOOLS[@]} -eq 0 ]]; then
    TOOLS=("${ALL_TOOLS[@]}")
fi

echo "============================================"
echo "  OpusTaxa Singularity Container Builder"
echo "============================================"
echo ""
echo "Definition dir: ${DEF_DIR}"
echo "Output dir:     ${SIF_DIR}"
echo "Build flag:     ${BUILD_FLAG:-'(sudo)'}"
echo "Tools to build: ${TOOLS[*]}"
echo ""

FAILED=()
BUILT=()

for tool in "${TOOLS[@]}"; do
    def_file="${DEF_DIR}/${tool}.def"
    sif_file="${SIF_DIR}/${tool}.sif"

    if [[ ! -f "$def_file" ]]; then
        echo "WARNING: Definition file not found: ${def_file} — skipping"
        FAILED+=("$tool")
        continue
    fi

    echo "--------------------------------------------"
    echo "Building: ${tool}"
    echo "  Definition: ${def_file}"
    echo "  Output:     ${sif_file}"
    echo "--------------------------------------------"

    if [[ -n "$BUILD_FLAG" ]]; then
        singularity build ${BUILD_FLAG} "${sif_file}" "${def_file}"
    else
        sudo singularity build "${sif_file}" "${def_file}"
    fi

    if [[ $? -eq 0 ]]; then
        BUILT+=("$tool")
        echo "SUCCESS: ${tool} → $(du -h "${sif_file}" | cut -f1)"
    else
        FAILED+=("$tool")
        echo "FAILED: ${tool}"
    fi
    echo ""
done

echo "============================================"
echo "  Build Summary"
echo "============================================"
echo "Built:  ${#BUILT[@]}/${#TOOLS[@]}"
if [[ ${#BUILT[@]} -gt 0 ]]; then
    echo "  OK: ${BUILT[*]}"
fi
if [[ ${#FAILED[@]} -gt 0 ]]; then
    echo "  FAILED: ${FAILED[*]}"
fi
echo ""
echo "Next steps:"
echo "  1. Copy .sif files to Setonix:"
echo "     scp ${SIF_DIR}/*.sif <user>@setonix.pawsey.org.au:/software/projects/<project>/<user>/containers/"
echo ""
echo "  2. Update config/config.yaml with container paths"
echo "  3. Run with: snakemake --use-singularity --singularity-args '-B /scratch -B /software'"
