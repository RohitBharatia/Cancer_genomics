#!/usr/bin/env bash
#SBATCH --job-name=multiqc
#SBATCH --output=logs/03_multiqc_%j.out
#SBATCH --error=logs/03_multiqc_%j.err
#SBATCH --time=00:30:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=1
#SBATCH --partition=pshort_el8
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=andri.widmer@unifr.ch

# Project-Root
PROJECT_DIR="${SLURM_SUBMIT_DIR:-$(pwd)}"

# Set paths
CONTAINER="/containers/apptainer/multiqc-1.33.sif"
INPUT_DIR="${PROJECT_DIR}/results/quality_control/fastp"
OUTPUT_DIR="${PROJECT_DIR}/results/quality_control/multiqc"

# Creates output directory; option -p makes it stable if directory already exists
mkdir -p "${OUTPUT_DIR}"

# Run multiqc on the fastp reports
apptainer exec "${CONTAINER}" multiqc \
    "${INPUT_DIR}" \
    -o "${OUTPUT_DIR}" \
    -n fastp_multiqc_report \
    --force