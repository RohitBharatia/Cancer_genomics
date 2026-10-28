# =============================================================================
# Variant prioritization (Part 5, second half)
#   HCC1395: reuses the VEP output of rules/annotation.smk
#   AD2881 : PASS filter -> VEP (+ ClinVar) -> filter_vep   (WGS, HNSCC)
#   both   : Rmarkdown report (plots, cancer gene overlap, ranking for top 3)
#
# Needs in config.yaml:  ad2881_vcf, cancer_genes   (optional: vep_filter)
# AD2881 rules are only active when ad2881_vcf is set.

CANCER_GENES = config["cancer_genes"]
AD2881_VCF = config.get("ad2881_vcf", "")
PRIO = f"{ANNOTATION}/prioritization"

# same filter as rules/annotation.smk, so HCC1395 and AD2881 are comparable
VEP_FILTER = config.get(
    "vep_filter",
    "(IMPACT is HIGH or IMPACT is MODERATE) or "
    "(SIFT match deleterious or PolyPhen match probably_damaging) or "
    "(ClinVar_CLNSIG match pathogenic)",
)

# annotated / filtered VEP tables per sample
VEP_TABLES = {
    "HCC1395": {
        "annotated": f"{ANNOTATION}/chr6chr17_mutect2_annotated_with_clinVar.txt",
        "filtered": f"{ANNOTATION}/chr6chr17_mutect2_annotated_with_clinVar_filtered.txt",
    },
}
if AD2881_VCF:
    VEP_TABLES["AD2881"] = {
        "annotated": f"{PRIO}/AD2881_PASS_annotated.txt",
        "filtered": f"{PRIO}/AD2881_PASS_filtered.txt",
    }

REPORT_SAMPLES = list(VEP_TABLES)


if AD2881_VCF:

    rule ad2881_pass:
        input:
            AD2881_VCF,
        output:
            vcf = f"{PRIO}/AD2881_PASS.vcf.gz",
            tbi = f"{PRIO}/AD2881_PASS.vcf.gz.tbi",
        log:
            "logs/prioritization/ad2881_pass.log"
        threads: 1
        resources:
            mem_mb = 2000,
            runtime = 30
        conda:
            "../envs/snakemake-env.yaml"
        shell:
            r"""
            {{
                bcftools view -f PASS {input:q} -Oz -o {output.vcf:q}
                bcftools index --tbi {output.vcf:q}
            }} > {log:q} 2>&1
            """


    rule ad2881_vep_annotate:
        input:
            vcf = f"{PRIO}/AD2881_PASS.vcf.gz",
            tbi = f"{PRIO}/AD2881_PASS.vcf.gz.tbi",
            clinvar = CLINVAR,
        output:
            txt = f"{PRIO}/AD2881_PASS_annotated.txt",
            html = f"{PRIO}/AD2881_PASS_annotated.txt_summary.html",
        params:
            cache = VEP_CACHE,
            cache_version = VEP_CACHE_VERSION,
        log:
            "logs/prioritization/ad2881_vep.log"
        threads: 4
        resources:
            mem_mb = 16000,
            runtime = 360
        conda:
            "../envs/annotation.yaml"
        shell:
            r"""
            vep \
                -i {input.vcf:q} \
                --format vcf \
                --cache \
                --offline \
                --dir_cache {params.cache:q} \
                --cache_version {params.cache_version} \
                --species homo_sapiens \
                --assembly GRCh38 \
                --everything \
                --pick \
                --fork {threads} \
                --force_overwrite \
                --custom {input.clinvar},ClinVar,vcf,exact,0,CLNSIG,CLNREVSTAT,CLNDN \
                --output_file {output.txt:q} \
                > {log:q} 2>&1
            """


    rule ad2881_vep_filter:
        input:
            f"{PRIO}/AD2881_PASS_annotated.txt"
        output:
            f"{PRIO}/AD2881_PASS_filtered.txt"
        params:
            filt = VEP_FILTER,
        log:
            "logs/prioritization/ad2881_filter.log"
        threads: 1
        resources:
            mem_mb = 4000,
            runtime = 30
        conda:
            "../envs/annotation.yaml"
        shell:
            r"""
            filter_vep \
                -i {input:q} \
                -o {output:q} \
                --force_overwrite \
                --filter "{params.filt}" \
                > {log:q} 2>&1
            """


rule vep_report:
    input:
        annotated = lambda wc: VEP_TABLES[wc.sample]["annotated"],
        filtered = lambda wc: VEP_TABLES[wc.sample]["filtered"],
        genes = CANCER_GENES,
        rmd = "report/vep_report.Rmd",
    output:
        f"{PRIO}/{{sample}}_report.html"
    wildcard_constraints:
        sample = "|".join(REPORT_SAMPLES)
    log:
        "logs/prioritization/{sample}_report.log"
    threads: 1
    resources:
        mem_mb = 8000,
        runtime = 30
    conda:
        "../envs/r_report.yaml"
    shell:
        r"""
        Rscript -e "rmarkdown::render( \
            input = '{input.rmd}', \
            output_file = normalizePath('{output}', mustWork = FALSE), \
            intermediates_dir = tempdir(), \
            knit_root_dir = getwd(), \
            params = list(sample = '{wildcards.sample}', \
                          annotated = '{input.annotated}', \
                          filtered = '{input.filtered}', \
                          genes = '{input.genes}'))" \
            > {log:q} 2>&1
        """