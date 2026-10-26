# VEP annotation plots (Part 5, "Visualization" slides)
# Run via Snakemake (rule vep_plots); paths come from the `snakemake` object.

log <- file(snakemake@log[[1]], open = "wt")
sink(log); sink(log, type = "message")

suppressPackageStartupMessages({
  library(tidyverse)
})

vep_file <- snakemake@input[[1]]
out <- snakemake@output

# --- read VEP default (tab) output; header lines start with "#" -------------
col_names <- c("Uploaded_variation", "Location", "Allele", "Gene", "Feature",
               "Feature_type", "Consequence", "cDNA_position", "CDS_position",
               "Protein_position", "Amino_acids", "Codons",
               "Existing_variation", "Extra")

vep_data <- read.table(vep_file, header = FALSE, sep = "\t",
                       comment.char = "#", quote = "",
                       col.names = col_names, stringsAsFactors = FALSE)

# pull KEY=value out of the Extra column; NA if the key is absent
extract_field <- function(extra, field) {
  str_match(extra, paste0("(?:^|;)", field, "=([^;]+)"))[, 2]
}

vep_data <- vep_data %>%
  mutate(
    chr           = factor(str_remove(Location, ":.*"), levels = c("chr6", "chr17")),
    IMPACT        = extract_field(Extra, "IMPACT"),
    SYMBOL        = extract_field(Extra, "SYMBOL"),
    VARIANT_CLASS = extract_field(Extra, "VARIANT_CLASS"),
    BIOTYPE       = extract_field(Extra, "BIOTYPE"),
    IMPACT        = factor(IMPACT, levels = c("HIGH", "MODERATE", "LOW", "MODIFIER"))
  ) %>%
  # one row can carry several consequences ("a,b" or "a&b") -> one row each
  separate_rows(Consequence, sep = "[,&]")

cat("Rows after splitting consequences:", nrow(vep_data), "\n")
cat("Unique variants:", n_distinct(vep_data$Uploaded_variation), "\n")

save_plot <- function(p, path, w = 7, h = 6) {
  ggsave(path, p, width = w, height = h, dpi = 150, bg = "white")
}

cons_order <- vep_data %>% count(Consequence) %>% arrange(n) %>% pull(Consequence)
vep_data <- vep_data %>% mutate(Consequence = factor(Consequence, levels = cons_order))

base_cons <- ggplot(vep_data, aes(x = Consequence)) +
  coord_flip() +
  theme_minimal() +
  labs(x = "Consequence Type", y = "Count")

# 1. consequence distribution
p1 <- base_cons + geom_bar() +
  labs(title = "Distribution of\nVariant Consequences")
save_plot(p1, out[["consequence"]])

# 2. consequence by chromosome
p2 <- p1 + facet_grid(~chr) + theme(legend.position = "bottom")
save_plot(p2, out[["consequence_chr"]], w = 10)

# 3. consequence coloured by impact
p3 <- ggplot(vep_data, aes(x = Consequence, fill = IMPACT)) +
  geom_bar() +
  coord_flip() +
  theme_minimal() +
  scale_fill_brewer(palette = "Set1", drop = FALSE) +
  labs(title = "Variant Consequences\nby Impact", x = "Consequence Type", y = "Count") +
  theme(legend.position = "bottom")
save_plot(p3, out[["impact"]])

# 4. ... by chromosome
p4 <- p3 + facet_grid(~chr)
save_plot(p4, out[["impact_chr"]], w = 10)

# 5. variant classes (count each variant once, not once per transcript)
p5 <- vep_data %>%
  distinct(Uploaded_variation, VARIANT_CLASS) %>%
  count(VARIANT_CLASS) %>%
  ggplot(aes(x = reorder(VARIANT_CLASS, n), y = n)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  theme_minimal() +
  labs(title = "Distribution of\nVariant Classes", x = "Variant Class", y = "Count (variants)")
save_plot(p5, out[["variant_class"]])

# 6. biotypes
p6 <- vep_data %>%
  distinct(Uploaded_variation, Feature, BIOTYPE) %>%
  count(BIOTYPE) %>%
  ggplot(aes(x = reorder(BIOTYPE, n), y = n)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  theme_minimal() +
  labs(title = "Distribution of\nBiotypes", x = "Biotype", y = "Count (variant x transcript)")
save_plot(p6, out[["biotype"]])

cat("Done.\n")