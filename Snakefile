configfile: "config/config.yml"

SAMPLES = config["samples"]
DATA = config["data_dir"]
QC = "results/quality_control"
TRIMMED = f"{QC}/fastp"               # fastp output (used by alignment)
ALIGN = "results/alignments"
BWA_IDX = f"{DATA}/bwa_idx/genome.fa"   # bwa-mem2 index prefix

include: "rules/qc.smk"
include: "rules/readalign_bam.smk"

rule all:
    input:
       # f"{QC}/multiqc/multiqc_report.html", #replace
        expand(f"{ALIGN}/{{sample}}.sorted.bam", sample=SAMPLES),
        expand(f"{ALIGN}/{{sample}}.sorted.bam.bai", sample=SAMPLES),
        expand(f"{ALIGN}/stats/{{sample}}.flagstat.txt", sample=SAMPLES),
