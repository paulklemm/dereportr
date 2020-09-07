#' Helper function for rendering the differential expression RMarkdown document
#' 
#' @export
#' @import rmarkdown magrittr
#'
#' @param path_config_json Path to experiment design json file
#' @param path_salmon_counts Path to salmon counts file
#' @param out_path Path for output
#' @param count_data Count data dataframe. Replaces path_salmon_counts
#' @param save_csv Output differentially expressed entries as csv file
#' @param save_excel Output differentially expressed entries as excel file
#' @param save_deseq_rds Output DESeq2 result object as rds file
#' @param biomart_attributes Attach biomart attributes to the resulting table
#' @param biomart_version Specify Ensembl version. Only required if biomart_attributes are defined
#' @param clean_output Clean intermediate rmarkdown render files
#' @param minimum_count For each gene at least one sample must equal or larger than this value to be included in the analysis
run_differential_expression <- function(
  path_config_json,
  path_salmon_counts = "",
  out_path,
  count_data = NULL,
  save_csv = TRUE,
  save_excel = TRUE,
  save_deseq_rds = TRUE,
  biomart_version = 100,
  biomart_attributes = "none",
  clean_output = TRUE
  minimum_count = 0
){
  if (path_salmon_counts == "" & is.null(count_data)) {
    stop("You have to either specify 'path_salmon_counts' or 'count_data'")
  }
  # Be sure the output path exists
  if (!dir.exists(out_path)) {
    paste0(
      "The output path ",
      out_path,
      " does not exist. I will create it now."
    ) %>%
    message()
    dir.create(
      path = out_path,
      showWarnings = TRUE,
      recursive = TRUE
    )
  }
  # Render command with all parameters
  rmarkdown::render(
    system.file("rmd/differential_expression.Rmd", package = "nfRNAseqDESeq2"),
    params = list(
      path_config_json = path_config_json,
      path_salmon_counts = path_salmon_counts,
      out_path = out_path,
      count_data = count_data,
      save_csv = save_csv,
      save_excel = save_excel,
      save_deseq_rds = save_deseq_rds,
      biomart_attributes = biomart_attributes,
      biomart_version = biomart_version
      minimum_count = minimum_count
    ),
    # Change the intermediate path to the output to avoid write access errors
    intermediates_dir = out_path,
    knit_root_dir = out_path,
    # Clean intermediate files created during rendering.
    clean = clean_output,
    output_dir = out_path,
    output_options = list(
      self_contained = TRUE
    )
  )
}

#' Create GO-term analysis for all comparisons of deseq2_diff.csv (created by nfRNAseqDESeq2)
#' @export
#' @import mygo magrittr dplyr readr
#' @param deseq2_diff_path Path to deseq2_diff.csv created by nfRNAseqDESeq2
#' @param out_path Path to output files
#' @param simplify_ontologies See mygo::createHTMLReport
#' @param do_gse See mygo::createHTMLReport
#' @param debug Save dataframe passed to mygo to allow for debugging
#' @examples
#'   goterm_analysis_of_all_comparisons(
#'     deseq2_diff_path = "/beegfs/scratch/bruening_scratch/pklemm/2019-11-sinika-rnaseq/analysis/results/DESeq2/deseq2_diff.csv",
#'     out_path = "/beegfs/scratch/bruening_scratch/pklemm/2019-11-sinika-rnaseq/analysis/results/goterm-analysis"
#'   )
goterm_analysis_of_all_comparisons <- function(
  deseq2_diff_path,
  out_path,
  simplify_ontologies = TRUE,
  do_gse = TRUE,
  debug = FALSE
) {
  # Read in DESeq2 result file
  deseq_output <- readr::read_csv(deseq2_diff_path)
  # Get all comparisons
  deseq_output %>%
    dplyr::select(comparison) %>%
    dplyr::distinct() %>%
    dplyr::pull() %>%
    # Iterate over all comparisons
    purrr::walk(function(current_comparison) {
      # Check if path for current comparison exists. If not, create it
      out_path_current_comparison <- file.path(out_path, current_comparison)
      if (!dir.exists(out_path_current_comparison)) {
        paste0("Directory '", out_path_current_comparison, "' does not exist, I will create it.") %>%
          warning()
        dir.create(out_path_current_comparison, recursive = TRUE)
      }
      # Print out status message for current analysis
      paste0(
        "Conducting GO-term analysis for comparison '",
        current_comparison,
        "', output folder: '",
        out_path_current_comparison, "'"
      ) %>%
        message()
      deseq_output %<>%
        # Filter for current comparison
        dplyr::filter(comparison == current_comparison) %>%
        # Create data frame compatible with mygo
        dplyr::rename(
          ensembl_gene_id = row,
          q_value = padj,
          fc = log2FoldChange,
          Symbol = external_gene_name
        ) %>%
        dplyr::select(ensembl_gene_id, q_value, fc, Symbol) %>%
        # Filter out NA values
        dplyr::filter(!is.na(q_value)) %>%
        # Check if we have enough differentially expressed genes
        (function(deseq_output) {
          if (deseq_output %>% dplyr::filter(q_value <= 0.05) %>% nrow() > 0) {
            if (debug) {
              # Print status message
              message(paste0("Debug mode, write output to ", out_path_current_comparison))
              # Write debug output
              deseq_output %>%
                readr::write_csv(
                  file.path(out_path_current_comparison, "deseq_output_for_mygo_debug.csv")
                )
            }
            # Start GO-term analysis
            deseq_output %>% mygo::createHTMLReport(
              output_path = out_path_current_comparison,
              simplify_ontologies = simplify_ontologies,
              do_gse = do_gse,
              # Always use background
              use_background = TRUE
            )
          } else {
            # Show warning and continue
            paste0(
              "No differentially expressed entries when filtering for '",
              current_comparison,
              "'"
            ) %>%
              warning()
          }
        })
    })
}
