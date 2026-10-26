# Cancer Genomics Practicals
This repository contains the practicals for the Cancer Genomics course of the Master in Bioinformatics at the University of Bern.

## Group members
Group #6
- Andy Mucyo Nkunzimana 19-325-760
- Andri Levi Widmer 20-105-581
- Rohit Mohan Bharatia 25-114-455

## Organisational matters

### File structure
```
Cancer_genomics/
├── Snakefile                      # Main workflow file
├── config/
│   └── config.yaml                # Samples and paths
├── rules/                         # Snakemake rules, one file per pipeline step
│   ├── qc.smk                     # FastQC, fastp, MultiQC (raw reads)
│   ├── readalign_bam.smk          # Alignment + SAM→BAM
│   ├── quality_calibration.smk    # MarkDuplicates, BQSR, calibration MultiQC
│   ├── variant_calling.smk        # Somatic variant calling
│   └── bam_qc.smk                 # Final BAM QC (header, flagstat, HsMetrics, MultiQC)
├── envs/                          # Conda environment files
│   └── snakemake-env.yaml
├── profiles/
│   └── slurm/config.yaml          # SLURM settings for Snakemake
├── scripts/
│   └── run_snakemake.sh           # Submits the workflow as a SLURM job
├── data/                          # Raw reads and references (not tracked by git)
├── results/                       # Output (not tracked by git)
│   ├── quality_control/
│   │   ├── fastqc/
│   │   ├── fastp/
│   │   └── multiqc/
│   ├── reads_alignment/
│   │   └── stats/
│   ├── BAM_processing/
│   ├── quality_calibration/
│   │   ├── BaseRecalibrator/
│   │   ├── ApplyBQSR/
│   │   └── multiqc/
│   ├── variants/
│   └── bam_qc/
│       ├── header/
│       ├── flagstat/
│       ├── intervals/
│       ├── hs_metrics/
│       └── multiqc/
├── logs/                          # Log files (not tracked by git)
│   ├── bam_qc/
│   └── multiqc/
└── README.md
```

|Rule|File|Description|Tool & version|
|--|--|--|--|
|`fastqc`|`rules/qc.smk`|Quality control of raw tumor and normal reads|FastQC 0.12.1|
|`fastp`|`rules/qc.smk`|Adapter and quality trimming|fastp 0.24.1|
|`multiqc`|`rules/qc.smk`|Aggregated QC report of FastQC and fastp|MultiQC 1.33|
|`bwa_mem2_align`|`rules/readalign_bam.smk`|Read alignment, streamed into BAM (temporary)|bwa-mem2 2.2.1, samtools>=1.19|
|`sort_bam`|`rules/readalign_bam.smk`|Coordinate-sort the BAM|samtools>=1.19|
|`index_bam`|`rules/readalign_bam.smk`|Create the .bai index|samtools>=1.19|
|`flagstat`|`rules/readalign_bam.smk`|Alignment summary of the sorted BAM|samtools>=1.19|
|`MarkDuplicate`|`rules/quality_calibration.smk`|Mark PCR/optical duplicates, write metrics, index|GATK 4.6.1.0|
|`CollectMultipleMetrics`|`rules/quality_calibration.smk`|Alignment summary metrics on the marked BAM|GATK 4.6.1.0|
|`BQSR`|`rules/quality_calibration.smk`|BaseRecalibrator: build the recalibration table (chr6 and chr17)|GATK 4.6.1.0|
|`Apply_BQSR`|`rules/quality_calibration.smk`|ApplyBQSR: write the recalibrated BAM and index it|GATK 4.6.1.0|
|`multiqc_calibration`|`rules/quality_calibration.smk`|MultiQC of FastQC, fastp, duplicates and alignment metrics|MultiQC 1.33|
|`mutect2`|`rules/variant_calling.smk`|Somatic SNV/indel calling, tumor vs matched normal|GATK 4.6.1.0 (Mutect2)|
|`filter_mutect_calls`|`rules/variant_calling.smk`|Flag calls as PASS or with the filter that failed|GATK 4.6.1.0 (FilterMutectCalls)|
|`bam_header`|`rules/bam_qc.smk`|Dump BAM header (sort order, contigs, @PG)|samtools>=1.19|
|`flagstat_bqsr`|`rules/bam_qc.smk`|Alignment summary on the recalibrated BAM|samtools>=1.19|
|`collect_hs_metrics`|`rules/bam_qc.smk`|Exome capture metrics (fold enrichment, on-target, coverage)|GATK 4.6.1.0|
|`multiqc_bam`|`rules/bam_qc.smk`|Final aggregated report|MultiQC 1.33|


Tool versions are defined in `envs/.yaml`. Snakemake builds the environments automatically on the first run.

### Data
The workflow expects:

```
data/normal.R1.fq.gz
data/normal.R2.fq.gz
data/tumor.R1.fq.gz
data/tumor.R2.fq.gz
```

References and resources come from the course directory `/data/courses/cancergenomics/2026/VAR_CALLING`, linked or copied into `data/`:

```
data/VAR_CALLING/bwa_idx/genome.fa (+ bwa-mem2 index files)   # alignment, BQSR, CollectMultipleMetrics
data/VAR_CALLING/dbsnp/GCF_000001405.40_alias.vcf.gz          # BQSR known sites
data/VAR_CALLING/known_indels/resources_broad_hg38_v0_Mills_and_1000G_gold_standard.indels.hg38.vcf.gz
data/var_calling/reference/ref_genome.fa (+ .fai, .dict)      # Mutect2, FilterMutectCalls
data/var_calling/reference/exome_regions.bed.interval_list    # Mutect2 and CollectHsMetrics targets
data/var_calling/resources/af-only-gnomad.hg38.subset.vcf.gz (+ .tbi)
data/var_calling/resources/1000g_pon.hg38.subset.vcf.gz (+ .tbi)
```

Mutect2 is run on the course-provided recalibrated BAMs (`var_calling.tumor_bam` and `var_calling.normal_bam` in `config/config.yaml`). It does not use the BAMs produced by `Apply_BQSR`.


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

Alignment metrics:

- CollectMultipleMetrics (GATK/Picard): https://gatk.broadinstitute.org/hc/en-us/articles/360036856051-CollectMultipleMetrics-Picard
- samtools flagstat: https://www.htslib.org/doc/samtools-flagstat.html

**Part 2: Variant calling**

Somatic calling and filtering:

- Mutect2: https://gatk.broadinstitute.org/hc/en-us/articles/360037593851-Mutect2
- FilterMutectCalls: https://gatk.broadinstitute.org/hc/en-us/articles/360036856831-FilterMutectCalls

**Part 3: BAM quality control**

- CollectHsMetrics (GATK/Picard): https://gatk.broadinstitute.org/hc/en-us/articles/360037055782-CollectHsMetrics-Picard
- MultiQC: https://seqera.io/multiqc/

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
source $HOME/miniforge3/bin/activate #adjust path to point at conda installation
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

## Environments

All environments are tracked in the global `envs/snakemake-env.yaml`
(snakemake, fastp, fastqc, multiqc, bwa-mem2, samtools, gatk4 4.6.1.0, openjdk 17, R).
Any other environment .yaml files are deprecated and not in use.

