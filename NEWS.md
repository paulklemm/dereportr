- `goterm_analysis_of_all_comparisons` can now run up- and down-regulated genes separateley

# dereportr 0.3.1

- Add full DESeq2 result table to "Differentially Expressed (DE) Genes" tab
# dereportr 0.3.0

- Drop support for providing flat files, require to provide data frames
- Major cleanup of output file
- Change name do `dereportr`

# dereportr 0.2.0

- Add `count_normalized` and `path_salmon_tpm` variables that allow for proper filtering of minimum expressed genes based on counts normalized on library size

# dereportr 0.1.0

- Add `minimum_padj` parameter setting the minimum threshold for padj for a gene to be differentially expressed
- Add `minimum_count` parameter where for each gene, at least one sample has to be equal or larger than this count
- Improve heat map output and add table of DE genes
- Improve description and layout of analysis doc

# dereportr 0.0.3

- Put deseq2 diff files into a separate folder
- Added ability to input count_data directly instead of Salmon counts
- Add goterm analysis function using the mygo package `goterm_analysis_of_all_comparisons`
- Close [Use TPM over counts file #5](https://github.com/paulklemm/dereportr/issues/5)
- Remove old debug mode, add reference to Xaringan
- Add [Use TPM over counts file #5](https://github.com/paulklemm/dereportr/issues/5)
- Add [support for multiple conditions](https://github.com/paulklemm/dereportr/issues/4)
