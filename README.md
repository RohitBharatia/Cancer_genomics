# Cancer Genomics Practicals
This repository contains the practicals for the Cancer Genomics course of the Master in Bioinformatics at the University of Bern.

## Group members
Group #6
- Andy Mucyo Nkunzimana
- Andri Levi Widmer
- Rohit Mohan Bharatia

## Organisational matters

### File structure
```
Cancer_genomics/
├── Snakefile                    # Main workflow file
├── config/
│   └── config.yml               # Samples and paths
├── rules/                       # Snakemake rules, one file per pipeline step
│   └── qc.smk
├── envs/                        # Conda environment files
├── profiles/
│   └── slurm/config.yaml        # SLURM settings for Snakemake
├── scripts/
│   └── run_snakemake.sh         # Submits the workflow as a SLURM job
├── data/                        # Raw reads (not tracked by git)
├── results/                     # Output (not tracked by git)
│   ├── quality_control/
│   │   ├── fastqc/
│   │   ├── fastp/
│   │   └── multiqc/
│   ├── reads_alignment/
│   ├── BAM_processing/
│   └── quality_calibration/
│       ├── BaseRecalibrator/
│       └── ApplyBQSR/
├── logs/                        # Log files (not tracked by git)
└── README.md
```

### Pipeline steps
| Rule | File | Description | Tool & version |
|---|---|---|---|
| `fastqc` | `rules/qc.smk` | Quality control of raw tumor and normal reads | FastQC 0.12.1 |
| `fastp` | `rules/qc.smk` | Adapter and quality trimming | fastp 0.24.1 |
| `multiqc` | `rules/qc.smk` | Aggregated QC report of FastQC and fastp | MultiQC 1.33 |

Tool versions are defined in `envs/*.yaml`. Snakemake builds the environments automatically on the first run.

### Data
Raw reads were obtained from `<add directory here>` on the UNIBE cluster and placed in `data/`. The workflow expects:
```
data/normal.R1.fq.gz
data/normal.R2.fq.gz
data/tumor.R1.fq.gz
data/tumor.R2.fq.gz
```

## Tools
Analysis was performed on the HPC cluster of the University of Bern.

**Workflow management**
- Snakemake: https://snakemake.readthedocs.io

**Part 1: Variant calling**

Initial QC:
- FastQC: https://www.bioinformatics.babraham.ac.uk/projects/fastqc/
- fastp: https://github.com/OpenGene/fastp
- MultiQC: https://seqera.io/multiqc/

Read alignment:
- bwa-mem2: https://github.com/bwa-mem2/bwa-mem2

BAM processing:
- MarkDuplicates (GATK/Picard): https://gatk.broadinstitute.org/hc/en-us/articles/360037052812-MarkDuplicates-Picard

Base quality recalibration:
- BaseRecalibrator: https://gatk.broadinstitute.org/hc/en-us/articles/360036898312-BaseRecalibrator
- ApplyBQSR: https://gatk.broadinstitute.org/hc/en-us/articles/360037055712-ApplyBQSR

## Setup

### 1. Install Miniforge (only once)
The conda version on the cluster is too old for Snakemake.
```bash
cd ~
wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
bash Miniforge3-Linux-x86_64.sh -b -p $HOME/miniforge3
rm Miniforge3-Linux-x86_64.sh
```

### 2. Create the Snakemake environment (only once)
```bash
source $HOME/miniforge3/bin/activate
cd /path/to/Cancer_genomics    # adjust path
conda env create -f envs/snakemake-env.yml
```

## Usage

### Activate the environment (every new session)
```bash
source $HOME/miniforge3/bin/activate
conda activate snakemake
cd /path/to/Cancer_genomics
```

### Dry run
Shows which jobs would run, without executing anything.
```bash
snakemake --profile profiles/slurm -n
```

### Run

As a SLURM job (recommended)

Submit from the repository root:
```bash
mkdir -p logs
sbatch scripts/run_snakemake.sh
```
**or**

in the current session. Be aware that a loss of connection will kill the running session.
```bash
mkdir -p logs
snakemake --profile profiles/slurm
```