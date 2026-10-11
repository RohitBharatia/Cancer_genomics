#!/usr/bin/env bash
#SBATCH --job-name=fastqc
#SBATCH --output=logs/01_fastqc_%j.out
#SBATCH --error=logs/01_fastqc_%j.err
#SBATCH --time=02:00:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=1
#SBATCH --partition=pshort_el8
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=andri.widmer@unifr.ch

# Project-Root
PROJECT_DIR="${SLURM_SUBMIT_DIR:-$(pwd)}"

# Set paths
CONTAINER="/containers/apptainer/fastqc-0.12.1.sif"
INPUT_DIR="${PROJECT_DIR}/data/"
OUTPUT_DIR="${PROJECT_DIR}/results/quality_control/fastqc/"

# Creates output directory; option -p makes it stable if directory already exists
mkdir -p "${OUTPUT_DIR}"

# Run FastQC for
apptainer exec "${CONTAINER}" fastqc \
    "${INPUT_DIR}"/*.fq.gz \
    -o "${OUTPUT_DIR}" \
    -t "${SLURM_CPUS_PER_TASK}"


