#!/usr/bin/env Rscript
# Run riskmetric scoring on all intended-for-use and import packages

library(jsonlite)
library(riskmetric)

classification <- fromJSON("package-classification.json")

# Score both intended-for-use and imports
all_pkgs <- c(classification$intended_for_use, classification$imports)

message("Running riskmetric on ", length(all_pkgs), " packages...")

results <- tryCatch({
  refs <- pkg_ref(all_pkgs)
  assessed <- pkg_assess(refs)
  scored <- pkg_score(assessed)
  scored
}, error = function(e) {
  message("Bulk scoring failed, falling back to per-package scoring: ", conditionMessage(e))
  # Fall back to scoring one at a time
  rows <- list()
  for (pkg in all_pkgs) {
    row <- tryCatch({
      ref <- pkg_ref(pkg)
      assessed <- pkg_assess(ref)
      scored <- pkg_score(assessed)
      scored
    }, error = function(e2) {
      message("  Failed to score ", pkg, ": ", conditionMessage(e2))
      data.frame(package = pkg, pkg_score = NA_real_, stringsAsFactors = FALSE)
    })
    rows[[length(rows) + 1]] <- row
  }
  do.call(rbind, rows)
})

# Build output
output <- list()
for (i in seq_len(nrow(results))) {
  pkg <- results$package[i]
  score <- if ("pkg_score" %in% names(results)) results$pkg_score[i] else NA_real_
  category <- if (pkg %in% classification$intended_for_use) "intended_for_use" else "import"
  output[[pkg]] <- list(
    package = pkg,
    category = category,
    riskmetric_score = round(score, 4)
  )
}

writeLines(toJSON(output, pretty = TRUE, auto_unbox = TRUE),
           con = file("riskmetric-results.json", open = "w", encoding = "UTF-8"))
message("Riskmetric results written to riskmetric-results.json")
