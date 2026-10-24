configfile: "config/config.yaml"

SAMPLES = config["samples"]
DATA = config["data_dir"]
QC = config["quality_control"]
TRIMMED = config["trimmed"]
ALIGN = config["align"]
REF = config["reference"]
KNOWN_SITES = config["known_sites"]
KNOWN_INDELS = config["known_indels"]
CALIBRATION = config["calibration"]
VARIANTS = config["VARIANTS"]

include: "rules/qc.smk"
include: "rules/readalign_bam.smk"
include: "rules/variant_calling.smk"
include: "rules/quality_calibration.smk"

rule all:
    default_target: True
    input:
<<<<<<< HEAD
        expand(
            f"{ALIGN}/{{sample}}.sorted.bam", sample=SAMPLES
        ),
        expand(
            f"{ALIGN}/{{sample}}.sorted.bam.bai", sample=SAMPLES
        ),
        expand(
            f"{ALIGN}/stats/{{sample}}.flagstat.txt", sample=SAMPLES
        ),
        expand(
            f"{CALIBRATION}/BQSR/{{sample}}_bqsr.bam",
            sample=SAMPLES
        ),
        expand(
            f"{CALIBRATION}/BQSR/{{sample}}_bqsr.bam.bai",
            sample=SAMPLES
        ),
        f"{VARIANTS}/somatic.filtered.vcf.gz",
        f"{CALIBRATION}/multiqc/multiqc_report.html"
=======
       # f"{QC}/multiqc/multiqc_report.html", #replace
        expand(f"{ALIGN}/{{sample}}.sorted.bam", sample=SAMPLES),
        expand(f"{ALIGN}/{{sample}}.sorted.bam.bai", sample=SAMPLES),
        expand(f"{ALIGN}/stats/{{sample}}.flagstat.txt", sample=SAMPLES),
        f"{config['VARIANTS']}/filter_summary.txt",
>>>>>>> 35a55f4 (PASS extraction)
