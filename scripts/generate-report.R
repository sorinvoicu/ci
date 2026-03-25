#!/usr/bin/env Rscript
# Generate consolidated validation report from all artifacts

library(rmarkdown)

message("Rendering validation report...")

render(
  input = "templates/validation-report.Rmd",
  output_file = file.path(getwd(), "validation-report.html"),
  output_format = html_document(
    toc = TRUE,
    toc_depth = 3,
    toc_float = TRUE,
    theme = "flatly"
  ),
  quiet = FALSE
)

message("Validation report written to validation-report.html")
