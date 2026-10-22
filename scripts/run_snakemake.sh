#!/usr/bin/env bash
#SBATCH --job-name=snakemake_main
#SBATCH --output=logs/snakemake_main_%j.out
#SBATCH --error=logs/snakemake_main_%j.err
#SBATCH --time=06:00:00
#SBATCH --mem=2G
#SBATCH --cpus-per-task=1
#SBATCH --partition=pibu_el8
#SBATCH --mail-type=END,FAIL
##SBATCH --mail-user=rohit.bharatia@students.unibe.ch     

WORKING_DIR='/data/users/ankunzimana/Cancer_genomics'
ENV_NAME="snakemake-env"

if conda env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
    conda activate snakemake-env
else
    conda env create -f "$WORKING_DIR/envs/snakemake-env.yaml" &&\
        conda activate snakemake-env
fi

cd $WORKING_DIR
snakemake --profile profiles/slurm
