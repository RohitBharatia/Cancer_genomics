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
QC = config["QC"]
TRIMMED = config["TRIMMED"]
ALIGN = config["ALIGN"]
BWA_IDX = config["BWA_IDX"]
VARIANTS = config["VARIANTS"]
ANNOTATION = config["annotation"]
CLINVAR = config["clinvar"]
VEP_CACHE = config["vep_cache"]
VEP_CACHE_VERSION = config["vep_cache_version"]


include: "rules/qc.smk"
include: "rules/readalign_bam.smk"
include: "rules/variant_calling.smk"
include: "rules/quality_calibration.smk"
include: "rules/annotation.smk"

rule all:
    default_target: True
    input:
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
       # f"{QC}/multiqc/multiqc_report.html", #replace
        expand(f"{ALIGN}/{{sample}}.sorted.bam", sample=SAMPLES),
        expand(f"{ALIGN}/{{sample}}.sorted.bam.bai", sample=SAMPLES),
        expand(f"{ALIGN}/stats/{{sample}}.flagstat.txt", sample=SAMPLES),
        f"{config['VARIANTS']}/filter_summary.txt",
        f"{ANNOTATION}/chr6chr17_mutect2_annotated_with_clinVar_filtered.txt",
        f"{ANNOTATION}/summary.txt",
        f"{ANNOTATION}/plots/01_consequences.png",
        f"{ANNOTATION}/plots/01_consequences.png",
        f"{ANNOTATION}/plots/02_consequences_by_chr.png",
        f"{ANNOTATION}/plots/03_consequences_by_impact.png",
        f"{ANNOTATION}/plots/04_consequences_by_impact_chr.png",
        f"{ANNOTATION}/plots/05_variant_classes.png",
        f"{ANNOTATION}/plots/06_biotypes.png"
