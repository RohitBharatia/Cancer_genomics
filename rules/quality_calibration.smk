# =============================================================================
# Base Quality score recalibration  


rule MarkDuplicate:
    input:
        bam = f"{ALIGN}/{{sample}}.sorted.bam"
    output:
        bam = f"{CALIBRATION}/MarkDuplicates/{{sample}}_marked.bam",
        bai = f"{CALIBRATION}/MarkDuplicates/{{sample}}_marked.bam.bai",
        metrics = f"{CALIBRATION}/MarkDuplicates/{{sample}}_metrics.txt"
    params:
        outdir = f"{CALIBRATION}/MarkDuplicates"
    log:
        "logs/gatk/{sample}gatk_MarkDuplicate.log"
    threads: 1
    resources:
        mem_mb = 16000,
        runtime = 240
    conda:
        "../envs/snakemake-env.yaml"
    shell:
        r"""
        mkdir -p {params.outdir:q} logs/gatk

        {{
            samtools quickcheck -v {input.bam:q}

            gatk MarkDuplicates \
                -I {input.bam:q} \
                -O {output.bam:q} \
                -M {output.metrics:q} \
                --REMOVE_DUPLICATES false \
                --CREATE_INDEX false

            samtools quickcheck -v {output.bam:q}
            samtools index {output.bam:q} {output.bai:q}
        }} > {log:q} 2>&1
        """


rule CollectMultipleMetrics:
    input:
        bam=f"{CALIBRATION}/MarkDuplicates/{{sample}}_marked.bam",
        bai=f"{CALIBRATION}/MarkDuplicates/{{sample}}_marked.bam.bai",
        ref=REF
    output:
        summary = f"{CALIBRATION}/CollectMultipleMetrics/{{sample}}/{{sample}}.alignment_summary_metrics"
    params:
        outdir = f"{CALIBRATION}/CollectMultipleMetrics/{{sample}}",
        prefix = f"{CALIBRATION}/CollectMultipleMetrics/{{sample}}/{{sample}}"
    log:
        "logs/gatk/{sample}.CollectMultipleMetrics.log"
    threads: 1
    resources:
        mem_mb=6000,
        runtime=90
    conda:
        "../envs/snakemake-env.yaml"
    shell:
        r"""
        mkdir -p {params.outdir:q} logs/gatk

        {{
            gatk CollectMultipleMetrics \
                -I {input.bam:q} \
                -O {params.prefix} \
                -R {input.ref:q} \
                --PROGRAM null \
                --PROGRAM CollectAlignmentSummaryMetrics
        }} > {log:q} 2>&1
        """


rule BQSR:
    input:
        bam = f"{CALIBRATION}/MarkDuplicates/{{sample}}_marked.bam",
        bai = f"{CALIBRATION}/MarkDuplicates/{{sample}}_marked.bam.bai",
        ref = REF,
        sites = KNOWN_SITES,
        indels = KNOWN_INDELS
    output:
        table = f"{CALIBRATION}/BQSR/{{sample}}_recal.table"
    log:
        "logs/gatk/{sample}gatk_recalibration.log"
    params: 
        outdir = f"{CALIBRATION}/BQSR",
        intervals = "-L chr6 -L chr17"
    threads: 1
    resources:
        mem_mb = 6000,
        runtime = 180
    conda:
        "../envs/snakemake-env.yaml"
    shell:
        r"""
        mkdir -p {params.outdir:q} logs/gatk

        gatk BaseRecalibrator \
            -R {input.ref:q} \
            -I {input.bam:q} \
            {params.intervals} \
            --known-sites {input.sites:q} \
            --known-sites {input.indels:q} \
            -O {output.table:q} \
            > {log:q} 2>&1

        """


rule Apply_BQSR:
    input:
        bam = f"{CALIBRATION}/MarkDuplicates/{{sample}}_marked.bam",
        bai = f"{CALIBRATION}/MarkDuplicates/{{sample}}_marked.bam.bai",
        table = f"{CALIBRATION}/BQSR/{{sample}}_recal.table",
        ref = REF
    output:
        bam = f"{CALIBRATION}/BQSR/{{sample}}_bqsr.bam",
        bai = f"{CALIBRATION}/BQSR/{{sample}}_bqsr.bam.bai"
    log:
        "logs/gatk/{sample}gatk_bqsr.log"
    params:
        outdir = f"{CALIBRATION}/BQSR" 
    threads: 1
    resources:
        mem_mb = 6000,
        runtime = 120
    conda:
        "../envs/snakemake-env.yaml"
    shell:
        r"""
        mkdir -p {params.outdir:q} logs/gatk

        {{
            gatk ApplyBQSR \
                -R {input.ref:q} \
                -I {input.bam:q} \
                --bqsr-recal-file {input.table:q} \
                --create-output-bam-index false \
                -O {output.bam:q}

            samtools quickcheck -v {output.bam:q}
            samtools index {output.bam:q} {output.bai:q}
        }} > {log:q} 2>&1
        """


rule multiqc_calibration:
    input:
        fastqc=expand(
            f"{QC}/fastqc/{{sample}}.{{read}}_fastqc.zip",
            sample=SAMPLES,
            read=["R1", "R2"]
        ),
        fastp=expand(
            f"{QC}/fastp/{{sample}}_fastp.json",
            sample=SAMPLES
        ),
        duplicates=expand(
            f"{CALIBRATION}/MarkDuplicates/{{sample}}_metrics.txt",
            sample=SAMPLES
        ),
        metrics=expand(
            f"{CALIBRATION}/CollectMultipleMetrics/{{sample}}/{{sample}}.alignment_summary_metrics",
            sample=SAMPLES
        )
    output:
        html=f"{CALIBRATION}/multiqc/multiqc_report.html"
    params:
        outdir=f"{CALIBRATION}/multiqc"
    log:
        "logs/multiqc/calibration.log"
    threads: 1
    resources:
        mem_mb=2000,
        runtime=30
    conda:
        "../envs/snakemake-env.yaml"
    shell:
        r"""
        mkdir -p {params.outdir:q} logs/multiqc

        multiqc \
            {input.fastqc:q} \
            {input.fastp:q} \
            {input.duplicates:q} \
            {input.metrics:q} \
            --outdir {params.outdir:q} \
            --filename multiqc_report.html \
            --no-data-dir \
            --force \
            > {log:q} 2>&1
        """
