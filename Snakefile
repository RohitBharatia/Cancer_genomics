configfile: "config/config.yml"

SAMPLES = config["samples"]
DATA = config["data_dir"]
QC = "results/quality_control"

include: "rules/qc.smk"

rule all:
    input:
        f"{QC}/multiqc/multiqc_report.html"
