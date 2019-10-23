
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

