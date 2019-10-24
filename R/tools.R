#' Helper function for rendering the differential expression RMarkdown document
#' 
#' @export
#' @import rmarkdown
#'
#' @param path_config_json Path to experiment design json file
#' @param path_salmon_counts Path to salmon counts file
#' @param out_path Path for output
#' @param save_csv Output differentially expressed entries as csv file
#' @param save_excel Output differentially expressed entries as excel file
#' @param save_deseq_rds Output DESeq2 result object as rds file
#' @param biomart_attributes Attach biomart attributes to the resulting table
#' @param biomart_version Specify Ensembl version. Only required if biomart_attributes are defined
run_differential_expression <- function(
  path_config_json,
  path_salmon_counts,
  out_path,
  save_csv = TRUE,
  save_excel = TRUE,
  save_deseq_rds = TRUE,
  biomart_version = 97,
  biomart_attributes = "none"
){
  # Render command with all parameters
  rmarkdown::render(
    system.file("rmd/differential_expression.Rmd", package = "nfRNAseqDESeq2"),
    params = list(
      path_config_json = path_config_json,
      path_salmon_counts = path_salmon_counts,
      out_path = out_path,
      save_csv = save_csv,
      save_excel = save_excel,
      save_deseq_rds = save_deseq_rds,
      biomart_attributes = biomart_attributes,
      biomart_version = biomart_version
    ),
    # Change the intermediate path to the output to avoid write access errors
    intermediates_dir = out_path,
    knit_root_dir = out_path,
    # Clean intermediate files created during rendering.
    clean = TRUE,
    output_dir = out_path,
    output_options = list(
      self_contained = TRUE
    )
  )
}