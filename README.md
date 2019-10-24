
# nfRNAseqDESeq2

<!-- badges: start -->
<!-- badges: end -->

This analysis largely follows the [DESeq2 vigniette](https://bioconductor.org/packages/release/bioc/vignettes/DESeq2/inst/doc/DESeq2.html).

The basis for the analysis is the [salmon](https://combine-lab.github.io/salmon/) output of the [NFCore](https://nf-co.re/) [RNAseq](https://github.com/nf-core/RNAseq) pipeline.
Since the pipeline is lacking support for differential gene expression, this package intents to midigate this problem.

## Installation

You can install the development version of nfRNAseqDESeq2 using [devtools](https://cran.r-project.org/web/packages/devtools/index.html) with:

``` r
devtools::install_github("paulklemm/nfRNAseqDESeq2")
```

## Example

The DESeq2 RMarkdown document required two important things.

1) A json file containing the group assignments for each sample
2) The path to the Salmon count file of the [NFCore](https://nf-co.re/) [RNAseq](https://github.com/nf-core/RNAseq) pipeline

### Sample group assignment json file

In order to run the DE pipeline, you need to specify a json file with group assignments for each sample, e.g.:

```json
{
  "groups": {
    "scrmbl": ["K002000135_65089", "K002000135_65095", "K002000135_65101"],
    "shMFF": ["K002000135_65083", "K002000135_65091", "K002000135_65099"]
  }
}
```

### Rendering the analysis document

```r
output_path <- getwd()
rmarkdown::render(
  system.file("rmd/differential_expression.Rmd", package = "nfRNAseqDESeq2"),
  params = list(
    path_config_json = "philipp_config.json",
    path_salmon_counts = "nf-rnaseq/results/salmon/salmon_merged_gene_counts.csv",
    out_path = output_path,
    save_csv = TRUE,
    save_excel = TRUE,
    save_deseq_rds = TRUE,
    biomart_version = 97,
    biomart_attributes = "external_gene_name",
  ),
  # Change the intermediate path to the output to avoid write access errors
  intermediates_dir = output_path,
  knit_root_dir = output_path,
  # clean: TRUE to clean intermediate files created during rendering.
  clean = TRUE,
  output_dir = output_path,
  output_options = list(
    self_contained = TRUE
  )
)
```
