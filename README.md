
# 🧬 🔬 nfRNAseqDESeq2

<!-- TOC depthFrom:2 -->

- [💾 Installation](#💾-installation)
- [🏀 Example](#🏀-example)
  - [Sample group assignment json file](#sample-group-assignment-json-file)
  - [Rendering the analysis document](#rendering-the-analysis-document)
  - [🐛 Debug Mode](#🐛-debug-mode)
- [⏳ History](#⏳-history)

<!-- /TOC -->

This analysis largely follows the [DESeq2 vigniette](https://bioconductor.org/packages/release/bioc/vignettes/DESeq2/inst/doc/DESeq2.html).

The basis for the analysis is the [salmon](https://combine-lab.github.io/salmon/) output of the [NFCore](https://nf-co.re/) [RNAseq](https://github.com/nf-core/RNAseq) pipeline.
Since the pipeline is lacking support for differential gene expression, this package intents to midigate this problem.

## 💾 Installation

You can install the development version of nfRNAseqDESeq2 using [devtools](https://cran.r-project.org/web/packages/devtools/index.html) with:

``` r
devtools::install_github("paulklemm/nfRNAseqDESeq2")
```

## 🏀 Example

The DESeq2 RMarkdown document required two important things.

1 A json file containing the group assignments for each sample
2 The path to the Salmon count file of the [NFCore](https://nf-co.re/) [RNAseq](https://github.com/nf-core/RNAseq) pipeline

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
nfRNAseqDESeq2::run_differential_expression(
  path_config_json = "philipp_config.json",
  path_salmon_counts = "nf-rnaseq/results/salmon/salmon_merged_gene_counts.csv",
  out_path = getwd()
)
```

You can also use the rmarkdown render function directly if you want to customize the rendering call.

```r

output_path <- getwd()
# Render command with all parameters
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
  )
)

# Second example
# Render command utilizing the default parameters
rmarkdown::render(
  system.file("rmd/differential_expression.Rmd", package = "nfRNAseqDESeq2"),
  params = list(
    path_config_json = "philipp_config.json",
    path_salmon_counts = "nf-rnaseq/results/salmon/salmon_merged_gene_counts.csv",
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

### 🐛 Debug Mode

For debugging the RMarkdown script, it's advised to use xaringan.

```r

xaringan::infinite_moon_reader(
  "inst/rmd/differential_expression.Rmd",
  params = list(
    path_config_json = "groups.json",
    path_salmon_counts = "results/salmon/salmon_merged_gene_counts.csv",
    out_path = "./",
    biomart_attributes = c("external_gene_name", "gene_biotype")
  )
)

```

## ⏳ History

- *2020-01-08*
  - Close [Use TPM over counts file #5](https://github.com/paulklemm/nfRNAseqDESeq2/issues/5)
- *2020-01-07*
  - Remove old debug mode, add reference to Xaringan
  - Add [Use TPM over counts file #5](https://github.com/paulklemm/nfRNAseqDESeq2/issues/5)
- *2019-11-12*
  - Add [support for multiple conditions](https://github.com/paulklemm/nfRNAseqDESeq2/issues/4)
