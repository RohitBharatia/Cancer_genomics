# =============================================================================
# BAM quality control on the final recalibrated BAMs (slides "Quality control of the bam files", Parts I-XIV)
#   samtools view -H  -> header check (sort order, contigs, @PG history)
#   samtools flagstat -> mapped / properly paired / duplicates
#   gatk CollectHsMetrics -> WES capture metrics (fold enrichment, on-target, coverage)
#   multiqc -> one report for everything

BAMQC = config["bam_qc"]["outdir"]
BAMQC_INTERVALS = config["bam_qc"]["intervals"]


rule bam_header:
    """Dump the BAM header: @HD sort order, @SQ contigs, @PG processing history."""
    input:
        bam = f"{CALIBRATION}/BQSR/{{sample}}_bqsr.bam",
        bai = f"{CALIBRATION}/BQSR/{{sample}}_bqsr.bam.bai"
    output:
        f"{BAMQC}/header/{{sample}}.bqsr.header.txt"
    log:
        "logs/bam_qc/{sample}.header.log"
    threads: 1
    resources:
        mem_mb = 1000,
        runtime = 10
    conda:
        "../envs/snakemake-env.yaml"
    shell:
        "samtools view -H {input.bam} > {output} 2> {log}"


rule flagstat_bqsr:
    """samtools flagstat on the final recalibrated BAM."""
    input:
        bam = f"{CALIBRATION}/BQSR/{{sample}}_bqsr.bam",
        bai = f"{CALIBRATION}/BQSR/{{sample}}_bqsr.bam.bai"
    output:
        f"{BAMQC}/flagstat/{{sample}}.bqsr.flagstat.txt"
    log:
        "logs/bam_qc/{sample}.flagstat.log"
    threads: 4
    resources:
        mem_mb = 2000,
        runtime = 30
    conda:
        "../envs/snakemake-env.yaml"
    shell:
        "samtools flagstat -@ {threads} {input.bam} > {output} 2> {log}"


rule collect_hs_metrics:
    """Hybrid-selection (exome capture) metrics. Bait = target = exome intervals, as in the slides."""
    input:
        bam = f"{CALIBRATION}/BQSR/{{sample}}_bqsr.bam",
        bai = f"{CALIBRATION}/BQSR/{{sample}}_bqsr.bam.bai",
        ref = REF,
        intervals = BAMQC_INTERVALS
    output:
        f"{BAMQC}/hs_metrics/{{sample}}.bqsr.hs_metrics.txt"
    params:
        outdir = f"{BAMQC}/hs_metrics"
    log:
        "logs/bam_qc/{sample}.hs_metrics.log"
    threads: 1
    resources:
        mem_mb = 8000,
        runtime = 60
    conda:
        "../envs/snakemake-env.yaml"
    shell:
        r"""
        mkdir -p {params.outdir:q} logs/bam_qc

        gatk --java-options "-Xmx6g" CollectHsMetrics \
            -I {input.bam:q} \
            -O {output:q} \
            -R {input.ref:q} \
            --BAIT_INTERVALS {input.intervals:q} \
            --TARGET_INTERVALS {input.intervals:q} \
            > {log:q} 2>&1
        """


rule multiqc_bam:
    """Final MultiQC: raw QC + trimming + duplicates + alignment metrics + flagstat + HsMetrics."""
    input:
        fastqc = expand(
            f"{QC}/fastqc/{{sample}}.{{read}}_fastqc.zip",
            sample=SAMPLES, read=["R1", "R2"]
        ),
        fastp = expand(
            f"{QC}/fastp/{{sample}}_fastp.json",
            sample=SAMPLES
        ),
        duplicates = expand(
            f"{CALIBRATION}/MarkDuplicates/{{sample}}_metrics.txt",
            sample=SAMPLES
        ),
        align_summary = expand(
            f"{CALIBRATION}/CollectMultipleMetrics/{{sample}}/{{sample}}.alignment_summary_metrics",
            sample=SAMPLES
        ),
        flagstat = expand(
            f"{BAMQC}/flagstat/{{sample}}.bqsr.flagstat.txt",
            sample=SAMPLES
        ),
        hs = expand(
            f"{BAMQC}/hs_metrics/{{sample}}.bqsr.hs_metrics.txt",
            sample=SAMPLES
        ),
        header = expand(
            f"{BAMQC}/header/{{sample}}.bqsr.header.txt",
            sample=SAMPLES
        )
    output:
        html = f"{BAMQC}/multiqc/multiqc_report.html"
    params:
        outdir = f"{BAMQC}/multiqc"
    log:
        "logs/multiqc/bam_qc.log"
    threads: 1
    resources:
        mem_mb = 2000,
        runtime = 30
    conda:
        "../envs/snakemake-env.yaml"
    shell:
        r"""
        mkdir -p {params.outdir:q} logs/multiqc

        multiqc \
            {input.fastqc:q} \
            {input.fastp:q} \
            {input.duplicates:q} \
            {input.align_summary:q} \
            {input.flagstat:q} \
            {input.hs:q} \
            --outdir {params.outdir:q} \
            --filename multiqc_report.html \
            --no-data-dir \
            --force \
            > {log:q} 2>&1
        """
