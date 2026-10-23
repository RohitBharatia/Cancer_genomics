# Somatic Variant Calling

VC = config["var_calling"]
VARIANTS = config["VARIANTS"]


def ref_files(fa):
    """Fasta and the two input files that GATK needs. ref_genome.fa, ref_genome.fa.fai, ref_genome.dict"""
    return [fa, fa + ".fai", fa.rsplit(".", 1)[0] + ".dict"]


rule mutect2:
    """Call somatic SNVs/indels in the tumor, using the normal to remove germline."""
    input:
        tumor      = VC["tumor_bam"],
        tumor_bai  = VC["tumor_bai"],
        normal     = VC["normal_bam"],
        normal_bai = VC["normal_bai"],
        ref        = ref_files(VC["ref"]),
        intervals  = VC["intervals"],
        germline   = VC["germline"],
        germ_tbi   = VC["germline"] + ".tbi",
        pon        = VC["pon"],
        pon_tbi    = VC["pon"] + ".tbi",
    output:
        vcf   = f"{VARIANTS}/somatic.vcf.gz",
        tbi   = f"{VARIANTS}/somatic.vcf.gz.tbi",
        stats = f"{VARIANTS}/somatic.vcf.gz.stats",
    params:
        normal_name = VC["normal_name"],
    log:
        "logs/mutect2/mutect2.log"
    threads: 4
    resources:
        mem_mb  = 16000,
        runtime = 240,
        slurm_partition = "pibu_el8",
    conda:
        "../envs/snakemake-env.yaml"
    shell:
        "gatk --java-options '-Xmx12g' Mutect2 "
        "-R {input.ref[0]} "
        "-L {input.intervals} "
        "-I {input.tumor} "
        "-I {input.normal} "
        "-normal {params.normal_name} "
        "--germline-resource {input.germline} "
        "--panel-of-normals {input.pon} "
        "--native-pair-hmm-threads {threads} "
        "-O {output.vcf} "
        "&> {log}"


rule filter_mutect_calls:
    """Annotate each call as PASS or with the reason(s) it failed."""
    input:
        vcf   = f"{VARIANTS}/somatic.vcf.gz",
        stats = f"{VARIANTS}/somatic.vcf.gz.stats",
        ref   = ref_files(VC["ref"]),
    output:
        vcf = f"{VARIANTS}/somatic.filtered.vcf.gz",
        tbi = f"{VARIANTS}/somatic.filtered.vcf.gz.tbi",
    log:
        "logs/mutect2/filter_mutect_calls.log"
    threads: 1
    resources:
        mem_mb  = 8000,
        runtime = 60,
        slurm_partition = "pibu_el8",
    conda:
        "../envs/snakemake-env.yaml"
    shell:
        "gatk --java-options '-Xmx6g' FilterMutectCalls "
        "-R {input.ref[0]} "
        "-V {input.vcf} "
        "--stats {input.stats} "
        "-O {output.vcf} "
        "&> {log}"