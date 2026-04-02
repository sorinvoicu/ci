#!/usr/bin/env Rscript
# Generate PDF validation report from all artifacts

library(rmarkdown)
library(tinytex)

message("Rendering PDF validation report...")

# Ensure missing LaTeX packages are auto-installed
options(tinytex.verbose = TRUE)

render(
  input          = "templates/validation-report-pdf.Rmd",
  output_file    = "validation-report.pdf",
  output_dir     = getwd(),
  knit_root_dir  = getwd(),
  quiet          = FALSE
)

message("PDF validation report written to validation-report.pdf")
