#!/usr/bin/env bash
#SBATCH --job-name=fastp
#SBATCH --output=logs/02_fastp_%j.out
#SBATCH --error=logs/02_fastp_%j.err
#SBATCH --time=02:00:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=1
#SBATCH --partition=pshort_el8
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=andri.widmer@unifr.ch


# Project-Root
PROJECT_DIR="${SLURM_SUBMIT_DIR:-$(pwd)}"

# Set paths
CONTAINER="/containers/apptainer/fastp_0.24.1.sif"
INPUT_DIR="${PROJECT_DIR}/data/"
OUTPUT_DIR="${PROJECT_DIR}/results/quality_control/fastp/"

# Creates output directory; option -p makes it stable if directory already exists
mkdir -p "${OUTPUT_DIR}"

# Run fastp for normal samples
apptainer exec "${CONTAINER}" fastp \
    -i "${INPUT_DIR}/normal.R1.fq.gz" \
    -I "${INPUT_DIR}/normal.R2.fq.gz" \
    -o "${OUTPUT_DIR}/normal_R1.trimmed.fq.gz" \
    -O "${OUTPUT_DIR}/normal_R2.trimmed.fq.gz" \
    -h "${OUTPUT_DIR}/normal_fastp.html" \
    -j "${OUTPUT_DIR}/normal_fastp.json" \
    -w "${SLURM_CPUS_PER_TASK:-1}"

# Run fastp for tumor samples
apptainer exec "${CONTAINER}" fastp \
    -i "${INPUT_DIR}/tumor.R1.fq.gz" \
    -I "${INPUT_DIR}/tumor.R2.fq.gz" \
    -o "${OUTPUT_DIR}/tumor_R1.trimmed.fq.gz" \
    -O "${OUTPUT_DIR}/tumor_R2.trimmed.fq.gz" \
    -h "${OUTPUT_DIR}/tumor_fastp.html" \
    -j "${OUTPUT_DIR}/tumor_fastp.json" \
    -w "${SLURM_CPUS_PER_TASK:-1}"
