#' Helper function for rendering the differential expression RMarkdown document
#' 
#' @export
#' @import rmarkdown magrittr
#'
#' @param path_config_json Path to experiment design json file
#' @param out_path Path for output
#' @param count_data Count data. Replaces path_salmon_counts
#' @param count_data_normalized Normalized count dataframe. Replaces path_salmon_tpm
#' @param save_intermediate Output intermediate files that can be used for debugging/custom analyses
#' @param biomart_attributes Attach biomart attributes to the resulting table
#' @param ensembl_version Specify Ensembl version. Only required if biomart_attributes are defined
#' @param clean_output Clean intermediate rmarkdown render files
#' @param minimum_count For each gene at least one sample must equal or larger than this value to be included in the analysis
#' @param minimum_padj Minimum padj value for a gene to be considered differentially expressed
#' @param biotypes_filter Filter genes for these biotypes
run_differential_expression <- function(
  path_config_json,
  out_path,
  count_data,
  count_data_normalized,
  save_intermediate = TRUE,
  ensembl_version = 101,
  biomart_attributes = "none",
  clean_output = TRUE,
  minimum_count = 0,
  minimum_padj = 0.05,
  biotypes_filter = "protein_coding"
){
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
    system.file("rmd/dereportr.Rmd", package = "dereportr"),
    params = list(
      path_config_json = path_config_json,
      out_path = out_path,
      count_data = count_data,
      count_data_normalized = count_data_normalized,
      save_intermediate = save_intermediate,
      biomart_attributes = biomart_attributes,
      ensembl_version = ensembl_version,
      biotypes_filter = biotypes_filter,
      minimum_count = minimum_count,
      minimum_padj = minimum_padj
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

#' Create GO-term analysis for all comparisons of deseq2_diff.csv (created by dereportr)
#' @export
#' @import mygo magrittr dplyr readr
#' @param deseq2_diff_path Path to deseq2_diff.csv created by dereportr
#' @param out_path Path to output files
#' @param simplify_ontologies See mygo::createHTMLReport
#' @param significance_cutoff Significance cutoff for both adjusted q-value and GO-term analysis
#' @param do_gse See mygo::createHTMLReport
#' @param debug Save dataframe passed to mygo to allow for debugging
#' @param up_and_down_separate Create a GO-term analysis not only for all DE genes, but also for up- and down-regulated ones
#' @param min_logfc Minimum log2 fold-change for a gene to be differentially up- or down-regulated
#' @examples
#'   goterm_analysis_of_all_comparisons(
#'     deseq2_diff_path = "/beegfs/scratch/bruening_scratch/pklemm/2019-11-sinika-rnaseq/analysis/results/DESeq2/deseq2_diff.csv",
#'     out_path = "/beegfs/scratch/bruening_scratch/pklemm/2019-11-sinika-rnaseq/analysis/results/goterm-analysis"
#'   )
goterm_analysis_of_all_comparisons <- function(
  deseq2_diff_path,
  out_path,
  simplify_ontologies = TRUE,
  significance_cutoff = 0.05,
  do_gse = TRUE,
  debug = FALSE,
  up_and_down_separate = TRUE,
  min_logfc = 0
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
      #' Helper function for running mygo
      #' @param deseq_output DESeq2 output table renamed to comply with mygo standards
      #' @param out_path Output path for the run
      run_mygo_helper <- function(deseq_output, mygo_out_path) {
        if (deseq_output %>% dplyr::filter(q_value <= 0.05) %>% nrow() > 0) {
          if (debug) {
            # Print status message
            message(paste0("Debug mode, write output to ", mygo_out_path))
            # Write debug output
            deseq_output %>%
              readr::write_csv(
                file.path(mygo_out_path, "deseq_output_for_mygo_debug.csv")
              )
          }
          # Start GO-term analysis
          deseq_output %>%
            mygo::createHTMLReport(
              output_path = mygo_out_path,
              simplify_ontologies = simplify_ontologies,
              significance_cutoff = significance_cutoff,
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
      }
      #' Helper function to create directory if it doesn't already exist
      create_dir <- function(directory)
      if (!dir.exists(directory)) {
        paste0("Directory '", directory, "' does not exist, I will create it.") %>%
          message()
        dir.create(directory, recursive = TRUE)
      }

      # Check if path for current comparison exists. If not, create it
      out_path_current_comparison <- file.path(out_path, current_comparison)
      out_path_current_comparison_up <- glue::glue("{out_path_current_comparison}_up")
      out_path_current_comparison_down <- glue::glue("{out_path_current_comparison}_down")
      # Create directories
      create_dir(out_path_current_comparison)
      if (up_and_down_separate) {
        create_dir(out_path_current_comparison_up)
        create_dir(out_path_current_comparison_down)
      }
      
      # Print out status message for current analysis
      glue::glue("Conducting GO-term analysis for comparison '{current_comparison}', output folder: '{out_path_current_comparison}'") %>%
        message()
      
      # Get dataframe for current comparison and rename it to comply with
      # mygo standard requirements
      deseq_out_comparison <-
        deseq_output %>%
        # Filter for current comparison
        dplyr::filter(comparison == current_comparison) %>%
        # Create data frame compatible with mygo
        dplyr::rename(
          q_value = padj,
          fc = log2FoldChange,
          Symbol = external_gene_name
        ) %>%
        dplyr::select(ensembl_gene_id, q_value, fc, Symbol) %>%
        # Filter out NA values
        dplyr::filter(!is.na(q_value))
      
      # Run all genes
      deseq_out_comparison %>%
        dplyr::filter(fc > min_logfc | fc < -min_logfc) %>%
        run_mygo_helper(out_path_current_comparison)
      # Run up-and down-regulated genes
      if (up_and_down_separate) {
        # Up-regulation
        deseq_out_comparison %>%
          dplyr::filter(fc > min_logfc) %>%
          run_mygo_helper(out_path_current_comparison_up)
        # Down-regulation
        deseq_out_comparison %>%
          dplyr::filter(fc < -min_logfc) %>%
          run_mygo_helper(out_path_current_comparison_down)
      }
    })
}
