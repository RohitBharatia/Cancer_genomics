configfile: "config/config.yaml"

SAMPLES = config["samples"]
DATA = config["data_dir"]
QC = config["QC"]
TRIMMED = config["TRIMMED"]
ALIGN = config["ALIGN"]
BWA_IDX = config["BWA_IDX"]


include: "rules/qc.smk"
include: "rules/readalign_bam.smk"
include: "rules/variant_calling.smk"

rule all:
    input:
       # f"{QC}/multiqc/multiqc_report.html", #replace
        expand(f"{ALIGN}/{{sample}}.sorted.bam", sample=SAMPLES),
        expand(f"{ALIGN}/{{sample}}.sorted.bam.bai", sample=SAMPLES),
        expand(f"{ALIGN}/stats/{{sample}}.flagstat.txt", sample=SAMPLES),
        f"{config['VARIANTS']}/somatic.filtered.vcf.gz",