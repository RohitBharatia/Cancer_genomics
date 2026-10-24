#!/usr/bin/env bash
#SBATCH --job-name=snakemake_main
#SBATCH --output=logs/snakemake_main_%j.out
#SBATCH --error=logs/snakemake_main_%j.err
#SBATCH --time=06:00:00
#SBATCH --mem=2G
#SBATCH --cpus-per-task=1
#SBATCH --partition=pibu_el8
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=andy.nkunzimana@students.unibe.ch     

WORKING_DIR='/data/users/ankunzimana/Cancer_genomics' 
ENV_NAME="snakemake-env"
ENV_FILE_PATH="$WORKING_DIR/envs/snakemake-env.yaml"
CONDA=`conda info --base`

source "$CONDA/bin/activate"

echo "verifying $ENV_NAME installation..."
if conda env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
    echo "$ENV_NAME already exists, updating and activating env..."
    # conda env update -n snakemake-env -f $ENV_FILE_PATH -q
    conda activate snakemake-env
    echo "$ENV_NAME activated!"
else
    echo "creating $ENV_NAME ..."
    conda env create -f "$WORKING_DIR/envs/snakemake-env.yaml" &&\
        conda activate snakemake-env
    echo "$ENV_NAME created and activated!"
fi

cd $WORKING_DIR
echo "Starting pipeline..."
snakemake --profile profiles/slurm
echo "analysis COMPLETED!"
