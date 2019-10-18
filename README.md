
# nfRNAseqDESeq2

<!-- badges: start -->
<!-- badges: end -->

The goal of nfRNAseqDESeq2 is to ...

## Installation

You can install the released version of nfRNAseqDESeq2 from [CRAN](https://CRAN.R-project.org) with:

``` r
install.packages("nfRNAseqDESeq2")
```

## Example

In order to run the DE pipeline, you need to specify a json file with group assignments for each sample, e.g.:

```json
{
  "groups": {
    "scrmbl": ["K002000135_65089", "K002000135_65095", "K002000135_65101"],
    "shMFF": ["K002000135_65083", "K002000135_65091", "K002000135_65099"]
  }
}
```
