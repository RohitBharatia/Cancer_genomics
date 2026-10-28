# =============================================================================
# Variant annotation & filtering (Part 5 of the course)
#   VEP (+ ClinVar custom annotation) -> annotated table
#   filter_vep                        -> high-priority variants only
#   shell summary                     -> consequence counts
#   R / ggplot2                       -> plots


rule vep_annotate:
    input:
        vcf = f"{VARIANTS}/somatic.filtered.PASS.vcf.gz",
        tbi = f"{VARIANTS}/somatic.filtered.PASS.vcf.gz.tbi",
        clinvar = CLINVAR
    output:
        txt = f"{ANNOTATION}/chr6chr17_mutect2_annotated_with_clinVar.txt",
        html = f"{ANNOTATION}/chr6chr17_mutect2_annotated_with_clinVar.txt_summary.html"
    params:
        outdir = ANNOTATION,
        cache = VEP_CACHE,
        cache_version = VEP_CACHE_VERSION
    log:
        "logs/vep/vep_annotate.log"
    threads: 2
    resources:
        mem_mb = 8000,
        runtime = 120
    conda:
        "../envs/annotation.yaml"
    shell:
        r"""
        mkdir -p {params.outdir:q} logs/vep

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
            --fork {threads} \
            --force_overwrite \
            --custom {input.clinvar},ClinVar,vcf,exact,0,CLNSIG,CLNREVSTAT,CLNDN \
            --output_file {output.txt:q} \
            > {log:q} 2>&1
        """


rule vep_filter:
    input:
        f"{ANNOTATION}/chr6chr17_mutect2_annotated_with_clinVar.txt"
    output:
        f"{ANNOTATION}/chr6chr17_mutect2_annotated_with_clinVar_filtered.txt"
    log:
        "logs/vep/vep_filter.log"
    threads: 1
    resources:
        mem_mb = 2000,
        runtime = 30
    conda:
        "../envs/annotation.yaml"
    shell:
        r"""
        filter_vep \
            -i {input:q} \
            -o {output:q} \
            --force_overwrite \
            --filter "(IMPACT is HIGH or IMPACT is MODERATE) or (SIFT match deleterious or PolyPhen match probably_damaging) or (ClinVar_CLNSIG match pathogenic)" \
            > {log:q} 2>&1
        """


rule vep_summary:
    input:
        f"{ANNOTATION}/chr6chr17_mutect2_annotated_with_clinVar_filtered.txt"
    output:
        f"{ANNOTATION}/summary.txt"
    threads: 1
    resources:
        mem_mb = 1000,
        runtime = 10
    shell:
        r"""
        {{
            echo "Filtered variant lines (variant x transcript):"
            grep -vc '^#' {input:q} || true
            echo
            echo "Unique variants:"
            grep -v '^#' {input:q} | cut -f1 | sort -u | wc -l
            echo
            echo "Mutation Type Summary (Consequence):"
            grep -v '^#' {input:q} | cut -f7 | sort | uniq -c | sort -nr
            echo
            echo "Genes hit (SYMBOL):"
            grep -v '^#' {input:q} | grep -o 'SYMBOL=[^;]*' | sort | uniq -c | sort -nr
            echo
            echo "ClinVar significance:"
            grep -v '^#' {input:q} | grep -o 'ClinVar_CLNSIG=[^;]*' | sort | uniq -c | sort -nr
        }} > {output:q}
        """


rule vep_plots:
    input:
        f"{ANNOTATION}/chr6chr17_mutect2_annotated_with_clinVar.txt"
    output:
        consequence = f"{ANNOTATION}/plots/01_consequences.png",
        consequence_chr = f"{ANNOTATION}/plots/02_consequences_by_chr.png",
        impact = f"{ANNOTATION}/plots/03_consequences_by_impact.png",
        impact_chr = f"{ANNOTATION}/plots/04_consequences_by_impact_chr.png",
        variant_class = f"{ANNOTATION}/plots/05_variant_classes.png",
        biotype = f"{ANNOTATION}/plots/06_biotypes.png"
    log:
        "logs/R/vep_plots.log"
    threads: 1
    resources:
        mem_mb = 4000,
        runtime = 20
    conda:
        "../envs/r_plots.yaml"
    script:
        "../scripts/vep_plots.R"