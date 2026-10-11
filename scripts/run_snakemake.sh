#!/usr/bin/env bash
#SBATCH --job-name=snakemake_main
#SBATCH --output=logs/snakemake_main_%j.out
#SBATCH --error=logs/snakemake_main_%j.err
#SBATCH --time=06:00:00
#SBATCH --mem=2G
#SBATCH --cpus-per-task=1
#SBATCH --partition=pibu_el8
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=andri.widmer@unifr.ch

source $HOME/miniforge3/bin/activate
conda activate snakemake

cd /data/users/awidmer/Cancer_genomics
snakemake --profile profiles/slurm