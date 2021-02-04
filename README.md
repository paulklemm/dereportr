
# 🧬 🔬 dereportr

<!-- TOC depthFrom:2 -->

- [💾 Installation](#💾-installation)
- [🏀 Example](#🏀-example)
  - [Sample group assignment json file](#sample-group-assignment-json-file)
  - [Rendering the analysis document](#rendering-the-analysis-document)
- [⏳ History](#⏳-history)

<!-- /TOC -->

This analysis largely follows the [DESeq2 vigniette](https://bioconductor.org/packages/release/bioc/vignettes/DESeq2/inst/doc/DESeq2.html).

## 💾 Installation

You can install the development version of dereportr using [devtools](https://cran.r-project.org/web/packages/devtools/index.html) with:

``` r
devtools::install_github("paulklemm/dereportr")
```

## 🏀 Example

You'll need

1 A json file containing the group assignments for each sample
2 Raw as well as library-size normalized counts

### Sample group assignment json file

In order to run the DE pipeline, you need to specify a json file with group assignments for each sample, e.g.:

```json

{
  "groups": {
    "BAT_W": ["BAT_W_2", "BAT_W_3", "BAT_W_4", "BAT_W_5"],
    "BAT_C": ["BAT_C_1", "BAT_C_2", "BAT_C_3", "BAT_C_4", "BAT_C_5"],
    "BAT_D": ["BAT_D_1", "BAT_D_2", "BAT_D_3", "BAT_D_4", "BAT_D_5"],
    "BAT_CD": ["BAT_CD_1", "BAT_CD_2", "BAT_CD_3", "BAT_CD_4", "BAT_CD_5"]
  },
  "comparisons": {
    "BAT_W vs BAT_C": {
      "group_a": "BAT_W",
      "group_b": "BAT_C"
    },
    "BAT_W vs BAT_D": {
      "group_a": "BAT_W",
      "group_b": "BAT_D"
    }
  }
}

```

Note that the comparisons section is optional.
When there are no comparisons specified, the tool will automatically compare all groups pairwise.

### Rendering the analysis document

You can use the built-in render function for the DESeq2 RMarkdown document.

```r
count_data <- readr::read_csv("nf-rnaseq/results/salmon/salmon_merged_gene_counts.csv")
count_data_normalized <- readr::read_csv("nf-rnaseq/results/salmon/salmon_merged_gene_tpm.csv")
dereportr::run_differential_expression(
  path_config_json = "philipp_config.json",
  count_data = count_data,
  count_data_normalized = count_data_normalized,
  out_path = getwd()
)
```

You can also use the rmarkdown render function directly if you want to customize the rendering call.

```r
count_data <- readr::read_csv("nf-rnaseq/results/salmon/salmon_merged_gene_counts.csv")
count_data_normalized <- readr::read_csv("nf-rnaseq/results/salmon/salmon_merged_gene_tpm.csv")
# Render command utilizing the default parameters
rmarkdown::render(
  system.file("rmd/differential_expression.Rmd", package = "dereportr"),
  params = list(
    path_config_json = "philipp_config.json",
    count_data = count_data,
    count_data_normalized = count_data_normalized,
    out_path = output_path
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

## ⏳ History

- *2021-02-04*
  - Drop support for providing flat files, require to provide data frames
  - Change name do `dereportr`
- *2020-11-20*
  - Add `count_normalized` and `path_salmon_tpm` variables that allow for proper filtering of minimum expressed genes based on counts normalized on library size
  - Bump version to `0.2.0`
- *2020-10-21*
  - Add `minimum_padj` parameter setting the minimum threshold for padj for a gene to be differentially expressed
  - Bump version to `0.1.0`
- *2020-09-07*
  - Add `minimum_count` parameter where for each gene, at least one sample has to be equal or larger than this count
  - Bump version to `0.0.6`
- *2020-05-08*
  - Improve heat map output and add table of DE genes. Bump version to `0.0.5`
- *2020-03-23*
  - Improve description and layout of analysis doc. Bump version to `0.0.4`
- *2020-03-14*
  - Put deseq2 diff files into a separate folder. Bump version to `0.0.3`
- *2020-02-28*
  - Added ability to input count_data directly instead of Salmon counts
- *2020-01-23*
  - Add goterm analysis function using the mygo package `goterm_analysis_of_all_comparisons`
- *2020-01-08*
  - Close [Use TPM over counts file #5](https://github.com/paulklemm/dereportr/issues/5)
- *2020-01-07*
  - Remove old debug mode, add reference to Xaringan
  - Add [Use TPM over counts file #5](https://github.com/paulklemm/dereportr/issues/5)
- *2019-11-12*
  - Add [support for multiple conditions](https://github.com/paulklemm/dereportr/issues/4)
