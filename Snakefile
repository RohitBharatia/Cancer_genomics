configfile: "config/config.yaml"

SAMPLES = config["samples"]
DATA = config["data_dir"]
QC = config["quality_control"]
TRIMMED = config["trimmed"]
ALIGN = config["align"]
REF = config["bwa_idx"]
KNOWN_SITES = config["known_sites"]
KNOWN_INDELS = config["known_indels"]
CALIBRATION = config["calibration"]


include: "rules/qc.smk"
include: "rules/readalign_bam.smk"
include: "rules/quality_calibration.smk"

rule all:
    input:
       # f"{QC}/multiqc/multiqc_report.html", #replace
        expand(f"{ALIGN}/{{sample}}.sorted.bam", sample=SAMPLES),
        expand(f"{ALIGN}/{{sample}}.sorted.bam.bai", sample=SAMPLES),
        expand(f"{ALIGN}/stats/{{sample}}.flagstat.txt", sample=SAMPLES),
