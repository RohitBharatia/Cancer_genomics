rule fastqc:
    input:
        r1 = f"{DATA}/{{sample}}.R1.fq.gz",
        r2 = f"{DATA}/{{sample}}.R2.fq.gz"
    output:
        f"{QC}/fastqc/{{sample}}.R1_fastqc.zip",
        f"{QC}/fastqc/{{sample}}.R2_fastqc.zip"
    log:
        "logs/fastqc/{sample}.log"
    threads: 2
    resources:
        mem_mb = 4000,
        runtime = 60
    conda:
        "../envs/snakemake-env.yaml"
    shell:
        "fastqc -t {threads} -o {QC}/fastqc {input.r1} {input.r2} &> {log}"


rule fastp:
    input:
        r1 = f"{DATA}/{{sample}}.R1.fq.gz",
        r2 = f"{DATA}/{{sample}}.R2.fq.gz"
    output:
        r1   = f"{QC}/fastp/{{sample}}_R1.trimmed.fq.gz",
        r2   = f"{QC}/fastp/{{sample}}_R2.trimmed.fq.gz",
        html = f"{QC}/fastp/{{sample}}_fastp.html",
        json = f"{QC}/fastp/{{sample}}_fastp.json"
    log:
        "logs/fastp/{sample}.log"
    threads: 4
    resources:
        mem_mb = 4000,
        runtime = 120
    conda:
        "../envs/snakemake-env.yaml"
    shell:
        "fastp -i {input.r1} -I {input.r2} "
        "-o {output.r1} -O {output.r2} "
        "-h {output.html} -j {output.json} "
        "-w {threads} &> {log}"


rule multiqc:
    input:
        expand(f"{QC}/fastqc/{{sample}}.{{read}}_fastqc.zip",
               sample=SAMPLES, read=["R1", "R2"]),
        expand(f"{QC}/fastp/{{sample}}_fastp.json", sample=SAMPLES)
    output:
        f"{QC}/multiqc/multiqc_report.html"
    log:
        "logs/multiqc/multiqc.log"
    resources:
        mem_mb = 4000,
        runtime = 30
    conda:
        "../envs/snakemake-env.yaml"
    shell:
        "multiqc {QC}/fastqc {QC}/fastp -o {QC}/multiqc --force &> {log}"
