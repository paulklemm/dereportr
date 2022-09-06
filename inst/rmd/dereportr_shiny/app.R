library(shiny)
library(shinydashboard)
library(plotly)
library(rmyknife)

# rmyknife::set_ggplot_defaults()

ui <-
  dashboardPage(
    skin = "black",
    header = dashboardHeader(title = "💎 DE-Reportr", disable = FALSE),
    sidebar = dashboardSidebar(
        # Have an overflowing sidebar
        tags$style(
          "#sidebarItemExpanded {
                overflow: auto;
                max-height: 100vh;
            }"
        ),
      shinybusy::add_busy_spinner(spin = "dots", position = "bottom-right"),
      helpText("Path to dereportr data. Typically you do not need to change this."),
      textInput(
        inputId = "dereportrpath",
        label = "dereportr output path",
        value = ""
      ),
      helpText("Table of the settings of the trapdiff run to be sure we have the right labels assigned."),
      tableOutput("settings"),
      helpText("Select a gene to highlight in the plots here. Alternatively you can select one in the table."),
      selectInput(
        "gene_id",
        "Highlight gene",
        choices = c(),
        multiple = TRUE
      )
    ),
    body = dashboardBody(
       fluidRow(
        box(
          width = 6,
          collapsible = TRUE,
          plotOutput("plot_group_counts")
        ),
        box(
          width = 6,
          collapsible = TRUE,
          plotOutput("volcano")
        )
      ),
      fluidRow(
        box(
          width = 12,
          collapsible = TRUE,
          DT::DTOutput("table")
        )
      )
    ),
     title = "dereportr"
  )

server <- function(input, output, session) {
  # Look for URL search changes
  observe({
    query <- parseQueryString(session$clientData$url_search)
    if (!is.null(query[['dereportrpath']])) {
      updateTextInput(session, "dereportrpath", value = query[['dereportrpath']])
    }
  })

  # Read data
  de <- shiny::reactive({
    shiny::validate(
      need(input$dereportrpath != "", "Please provide valid data set")
    )
    
    glue::glue("{input$dereportrpath}/deseq2_diff.csv") %>%
      readr::read_csv() %>%
      dplyr::mutate(gene_id = glue::glue("{external_gene_name}_{ensembl_gene_id}"))
  })
  
  col_data <- shiny::reactive({
    shiny::validate(
      need(input$dereportrpath != "", "Please provide valid data set")
    )
    glue::glue("{input$dereportrpath}/intermediates/col_data.csv") %>%
      readr::read_csv()
  })
  counts <- shiny::reactive({
    shiny::validate(
      need(input$dereportrpath != "", "Please provide valid data set")
    )
    glue::glue("{input$dereportrpath}/intermediates/deseq_normalized_counts.csv.gz") %>%
      readr::read_csv() %>%
      dplyr::mutate(
        sample_id = forcats::as_factor(sample_id)
      )
  })

  de_wide <- shiny::reactive({
    shiny::validate(
      need(input$dereportrpath != "", "Please provide valid data set")
    )
    de() %>%
      dplyr::select(-c(baseMean, lfcSE, stat, pvalue)) %>%
      tidyr::pivot_wider(
        names_from = comparison,
        values_from = c(padj, log2FoldChange),
        # For some reason we'll get problems with duplicate entries if we don't do this
        values_fn = mean
      ) %>%
      rmyknife::attach_biomart(attributes = "description")
  })

  # Update Gene select input
  observe({
    selected_gene <- tryCatch(
      de_wide() %>%
        .$gene_id %>%
        .[1],
      error = function(cond){ NULL }
    )
    gene_choices <- tryCatch(
      de_wide() %>%
        dplyr::select(gene_id) %>%
        dplyr::distinct() %>%
        dplyr::pull(),
      error = function(cond){ NULL }
    )
    if (!is.null(input$table_rows_selected)) {
      selected_gene <- de_wide() %>%
        dplyr::slice(input$table_rows_selected) %>%
        .$gene_id
    }
    updateSelectizeInput(
      session,
      "gene_id",
      choices = gene_choices,
      selected = selected_gene,
      server = TRUE
    )
  })

  output$table <- DT::renderDataTable({
    de_wide() %>%
      dplyr::select(ensembl_gene_id, external_gene_name, description, dplyr::everything()) %>%
      # Replace long names to make list smaller
      (function(dat) {
        colnames(dat) <- stringr::str_replace_all(colnames(dat), "log2FoldChange", "fc")
        colnames(dat) <- stringr::str_replace_all(colnames(dat), "padj", "p")
        colnames(dat) <- stringr::str_replace_all(colnames(dat), "interaction_effect", "interaction")
        return(dat)
      }) %>%
      # Round all values to 4 decimals
      dplyr::mutate_if(is.numeric, round, 4) %>%
      DT::datatable(
        extensions = c("Scroller", "Buttons"),
        selection = "single",
        filter = list(position = "top"),
        options = list(
          # Remove search bar but leave filter
          # https://stackoverflow.com/a/35627085
          # sDom  = '<"top">lrt<"bottom">ip',
          # Enable colvis button
          dom = "Bfrtip",
          # Define hidden columns
          columnDefs = list(list(
            targets = 0:3, visible = FALSE
          )),
          buttons = c("colvis", "copy", "csv", "excel", "pdf", "print"),
          scrollX = TRUE
          # Makes the table more responsive when it's really big
          # scrollY = 250,
          # scroller = TRUE
        )
      )
  })
  
  output$volcano <- shiny::renderPlot({
    de() %>%
      rmyknife::plot_volcano(
        highlight = input$gene_id %>%
          stringr::str_extract(pattern = "^(.)+_") %>%
          stringr::str_remove("_")
      ) +
      ggplot2::facet_grid(
        .~comparison,
        scales = "free"
      )
  })

  output$plot_group_counts <- shiny::renderPlot({
    # browser()
    counts() %>%
      dplyr::mutate(
        gene_id = paste0(external_gene_name, "_", ensembl_gene_id),
        sample_id = sample_id,
        group = treatment
      ) %>%
      dplyr::filter(gene_id %in% input$gene_id) %>%
      ggplot2::ggplot(
        mapping = ggplot2::aes(
          x = group,
          y = count
        )
      ) +
      # Remove outliers from boxplot to not confuse them with the jitter data points
      ggplot2::geom_boxplot(outlier.shape = NA, color = "grey") +
      ggplot2::geom_jitter(
        mapping = ggplot2::aes(color = sample_id),
        width = 0.1,
        height = 0
      ) +
      ggplot2::ggtitle(
        "DESeq2 Counts per condition"
      ) +
      ggplot2::facet_grid(
        external_gene_name~.,
        scales = "free"
      )
  })
}

shinyApp(ui, server)
