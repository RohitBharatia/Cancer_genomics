# =============================================================================
# Read alignment & BAM processing  (Rohit)
#   bwa-mem2 mem  ->  samtools view -b   (unsorted BAM, temporary)
#   samtools sort ->  coordinate-sorted BAM
#   samtools index -> .bai
#   samtools flagstat -> quick alignment sanity check
#
# Assumes the main Snakefile defines (or loads from config.yaml):
#   TRIMMED  - fastp output dir (results/quality_control/fastp)
#   ALIGN    - output dir for BAMs (results/alignments)
#   BWA_IDX  - bwa-mem2 index prefix: <...>/bwa_idx/genome.fa
#   SAMPLES  - ["normal", "tumor"]
# See Snakefile_proposed and config/config_additions.yml.
# =============================================================================

# The existing bwa_idx/ folder already holds a complete bwa-mem2 index
# (genome.fa.0123, .amb, .ann, .bwt.2bit.64, .pac), so no index rule is needed.


# -----------------------------------------------------------------------------
# OPTIONAL / NOT NEEDED: the index in bwa_idx/ is already complete. Kept only as
# a reference in case it ever has to be rebuilt.
# -----------------------------------------------------------------------------
# rule bwa_mem2_index:
#     input:
#         ref = REF
#     output:
#         multiext(BWA_IDX, ".0123", ".amb", ".ann", ".bwt.2bit.64", ".pac")
#     log:
#         "logs/bwa_mem2_index/index.log"
#     threads: 4
#     resources:
#         mem_mb = 64000,     # human genome index build needs a lot of RAM
#         runtime = 240
#     conda:
#         "../envs/alignment.yaml"   # relative to THIS file (rules/) -> project_root/envs/
#     shell:
#         "bwa-mem2 index -p {BWA_IDX} {input.ref} &> {log}"


rule bwa_mem2_align:
    """Map paired reads with bwa-mem2 and stream straight into samtools (no SAM on disk)."""
    input:
        r1 = f"{TRIMMED}/{{sample}}_R1.trimmed.fq.gz",
        r2 = f"{TRIMMED}/{{sample}}_R2.trimmed.fq.gz",
        # fail early (at DAG build) if the index is missing
        idx = multiext(BWA_IDX, ".0123", ".amb", ".ann", ".bwt.2bit.64", ".pac"),
    output:
        bam = temp(f"{ALIGN}/{{sample}}.aligned.bam")    # deleted once sorting succeeded
    params:
        ref = BWA_IDX,
        # Read group: required by GATK (MarkDuplicates, BQSR, Mutect2 ...).
        # r"" keeps \t literal so bwa-mem2 itself expands it (as in the hint script).
        rg = r"@RG\tID:{sample}\tSM:{sample}\tPL:ILLUMINA\tLB:{sample}",
        view_threads = 4,
    log:
        "logs/bwa_mem2/{sample}.log"
    threads: 8         # chr6+7 subset (~330 Mb) and ~590 MB R1: 8 is plenty (+4 samtools view threads)
    resources:
        # 12000 was OOM-killed: the index in bwa_idx/ is bigger than chr6+7 alone (probably the full genome).
        # bwa-mem2 loads the whole index into RAM, so use ~1.5x the size of `du -shc data/var_calling/bwa_idx/genome.fa.*`
        mem_mb = 40000,    # TODO: tune to the real index size
        runtime = 120      # minutes; generous for this subset, adjust after the first run (see seff <jobid>)
    conda:
        "../envs/alignment.yaml"
    shell:
        # pipe: bwa-mem2 -> stdout (SAM) -> samtools view (reads "-" = stdin) -> BAM
        "bwa-mem2 mem -t {threads} "
        "-R '{params.rg}' "
        "{params.ref} {input.r1} {input.r2} 2> {log} "
        "| samtools view -b -@ {params.view_threads} -o {output.bam} -"


rule sort_bam:
    """Coordinate-sort the BAM."""
    input:
        f"{ALIGN}/{{sample}}.aligned.bam"
    output:
        f"{ALIGN}/{{sample}}.sorted.bam"
    log:
        "logs/samtools_sort/{sample}.log"
    threads: 4
    resources:
        mem_mb = 10000,    # samtools sort uses -m per thread (below) x threads
        runtime = 60
    conda:
        "../envs/alignment.yaml"
    shell:
        # -T: temp file prefix; put it in $TMPDIR if the cluster provides one
        "samtools sort -@ {threads} -m 2G "
        "-T ${{TMPDIR:-/tmp}}/{wildcards.sample}.sort "
        "-o {output} {input} &> {log}"


rule index_bam:
    """Create the .bai index for the sorted BAM."""
    input:
        f"{ALIGN}/{{sample}}.sorted.bam"
    output:
        f"{ALIGN}/{{sample}}.sorted.bam.bai"
    log:
        "logs/samtools_index/{sample}.log"
    threads: 4
    resources:
        mem_mb = 2000,
        runtime = 30
    conda:
        "../envs/alignment.yaml"
    shell:
        "samtools index -@ {threads} {input} {output} &> {log}"


rule flagstat:
    """Alignment summary (mapped %, properly paired ...) - cheap sanity check."""
    input:
        bam = f"{ALIGN}/{{sample}}.sorted.bam",
        bai = f"{ALIGN}/{{sample}}.sorted.bam.bai"
    output:
        f"{ALIGN}/stats/{{sample}}.flagstat.txt"
    log:
        "logs/samtools_flagstat/{sample}.log"
    threads: 2
    resources:
        mem_mb = 2000,
        runtime = 30
    conda:
        "../envs/alignment.yaml"
    shell:
        "samtools flagstat -@ {threads} {input.bam} > {output} 2> {log}"


# -----------------------------------------------------------------------------
# Targets added to rule all in the Snakefile:
#
#   expand(f"{ALIGN}/{{sample}}.sorted.bam",           sample=SAMPLES),
#   expand(f"{ALIGN}/{{sample}}.sorted.bam.bai",       sample=SAMPLES),
#   expand(f"{ALIGN}/stats/{{sample}}.flagstat.txt",   sample=SAMPLES),
#
# and include this file:
#   include: "rules/alignment.smk"
#
# TODO (teammates / later steps): MarkDuplicates, BQSR (uses dbsnp/ and
# known_indels/) will take {sample}.sorted.bam as input.
# -----------------------------------------------------------------------------
