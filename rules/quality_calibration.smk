# =============================================================================
# Base Quality score recalibration  

rule MarkDuplicate:
    input:
        expand(f"{ALIGN}/{{sample}}.sorted.bam", sample=SAMPLES)
    output:
        out_dir = f"{CALIBRATION}/MarkDuplicates",
        out_bam = expand(f"{CALIBRATION}/MarkDuplicates/{{sample}}_marked.bam", sample=SAMPLES),
        out_metrics = expand(f"{CALIBRATION}/MarkDuplicates/{{sample}}_metrics.txt", sample=SAMPLES)
    log:
        expand("logs/gatk/{sample}gatk_MarkDuplicate.log", sample=SAMPLES)
    threads: 4
    resources:
        mem_mb = 4000,
        runtime = 30
    conda:
        "../envs/snakemake-env.yaml"
    shell:
        "makedir -p {output.out_dir} && gatk MarkDuplicates \
        -I {input} -O {output.out_bam} -M {output.out_metrics} &> {log}"
        "samtools index {output.out_bam}"


rule CollectMultipleMetrics:
    input:
        expand(f"{ALIGN}/{{sample}}.sorted.bam", sample=SAMPLES)
    output:
        out_dir = f"{CALIBRATION}/CollectMultiMetrics",
        out_metrics = expand(f"{CALIBRATION}/CollectMultipleMetrics/{{sample}}_MultiMetrics", sample=SAMPLES)
    params:
        ref = REF
    log:
        expand("logs/gatk/{sample}gatk_MultiMetrics.log", sample=SAMPLES)
    threads: 4
    resources:
        mem_mb = 4000,
        runtime = 30
    conda:
        "../envs/snakemake-env.yaml"
    shell:
        "makedir -p {output.out_dir} && gatk MarkDuplicates \
        -I {input} -O {output.out_metrics} -R {params.ref} &> {log}"
        "multiqc {QC}/fastqc {QC}/fastp {output.out_dir} -o {CALIBRATION} &> {log}"

rule BSQR:
    input:
        expand(f"{CALIBRATION}/MarkDuplicates/{{sample}}_marked.bam", sample=SAMPLES)
    output:
        out_dir = f"{CALIBRATION}/BSQR",
        table = expand(f"{CALIBRATION}/BSQR/{{sample}}_recal.table", sample=SAMPLES)
    log:
        expand("logs/gatk/{sample}gatk_recalibration.log", sample=SAMPLES)
    params: 
        site = KNOWN_SITES,
        indels = KNOWN_INDELS
    threads: 4
    resources:
        mem_mb = 4000,
        runtime = 30
    conda:
        "../envs/snakemake-env.yaml"
    shell:
        "makedir -p {output.out_dir} && gatk BaseRecalibrator -R {REF} -I {input} \
        --known-sites {params.sites} -- known-sites {params.indels} \
        -O {output.table} &> {log}"


rule Apply_BSQR:
    input:
        bam = expand(f"{CALIBRATION}/MarkDuplicates/{{sample}}_marked.bam", sample=SAMPLES),
        table = expand(f"{CALIBRATION}/{{sample}}_recal.table", sample=SAMPLES)
    output:
        expand(f"{CALIBRATION}/BSQR/{{sample}}_bsqr.bam", sample=SAMPLES)
    log:
        expand("logs/gatk/{sample}gatk_bsqr.log", sample=SAMPLES)
    params: 
        ref = REF
    threads: 4
    resources:
        mem_mb = 4000,
        runtime = 30
    conda:
        "../envs/snakemake-env.yaml"
    shell:
        "gatk ApplyBSQR -R {REF} -I {input.bam} --bsqr-recal-file {input.table} -O {output}"
        "samtools index {output}"
