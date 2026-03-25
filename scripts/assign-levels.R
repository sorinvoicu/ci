#!/usr/bin/env Rscript
# Assign validation levels (1/2/3) based on thresholds

library(jsonlite)
library(yaml)

thresholds <- read_yaml("validation-thresholds.yml")
classification <- fromJSON("package-classification.json")
validation <- fromJSON("validation-results.json")
riskmetric <- fromJSON("riskmetric-results.json")

assignments <- list()

# Level 1: Base and recommended packages
for (pkg in classification$base) {
  assignments[[pkg]] <- list(
    package = pkg,
    level = 1L,
    reason = "Base/recommended package"
  )
}

# Intended-for-use packages: Level 2 or 3
for (pkg in classification$intended_for_use) {
  coverage <- NA_real_
  risk_score <- NA_real_

  # Get coverage from validation results
  if (!is.null(validation[[pkg]])) {
    coverage <- validation[[pkg]]$coverage_pct
  }

  # Get riskmetric score
  if (!is.null(riskmetric[[pkg]])) {
    risk_score <- riskmetric[[pkg]]$riskmetric_score
  }

  has_coverage <- !is.null(coverage) && !is.na(coverage) &&
    coverage >= thresholds$coverage_threshold
  has_risk <- !is.null(risk_score) && !is.na(risk_score) &&
    risk_score <= thresholds$riskmetric_threshold

  if (has_coverage && has_risk) {
    level <- 2L
    reason <- sprintf("Coverage %.1f%% >= %d%% and riskmetric %.4f <= %.1f",
                      coverage, thresholds$coverage_threshold,
                      risk_score, thresholds$riskmetric_threshold)
  } else {
    level <- 3L
    parts <- character(0)
    if (!has_coverage) {
      parts <- c(parts, sprintf("coverage %s < %d%%",
                                if (is.null(coverage) || is.na(coverage)) "NA" else sprintf("%.1f%%", coverage),
                                thresholds$coverage_threshold))
    }
    if (!has_risk) {
      parts <- c(parts, sprintf("riskmetric %s > %.1f",
                                if (is.null(risk_score) || is.na(risk_score)) "NA" else sprintf("%.4f", risk_score),
                                thresholds$riskmetric_threshold))
    }
    reason <- paste("Manual review needed:", paste(parts, collapse = "; "))
  }

  assignments[[pkg]] <- list(
    package = pkg,
    level = level,
    reason = reason,
    coverage_pct = coverage,
    riskmetric_score = risk_score
  )
}

# Import packages: assign Level 2 or 3 based on riskmetric only (no coverage required)
for (pkg in classification$imports) {
  risk_score <- NA_real_
  if (!is.null(riskmetric[[pkg]])) {
    risk_score <- riskmetric[[pkg]]$riskmetric_score
  }

  has_risk <- !is.null(risk_score) && !is.na(risk_score) &&
    risk_score <= thresholds$riskmetric_threshold

  if (has_risk) {
    level <- 2L
    reason <- sprintf("Import package; riskmetric %.4f <= %.1f", risk_score, thresholds$riskmetric_threshold)
  } else {
    level <- 3L
    reason <- sprintf("Import package; riskmetric %s > %.1f — review recommended",
                      if (is.null(risk_score) || is.na(risk_score)) "NA" else sprintf("%.4f", risk_score),
                      thresholds$riskmetric_threshold)
  }

  assignments[[pkg]] <- list(
    package = pkg,
    level = level,
    reason = reason,
    riskmetric_score = risk_score
  )
}

cat(as.character(toJSON(assignments, pretty = TRUE, auto_unbox = TRUE)), file = "level-assignments.json")

# Summary
levels <- vapply(assignments, function(x) x$level, integer(1))
message("Level assignments written to level-assignments.json")
message("  Level 1: ", sum(levels == 1))
message("  Level 2: ", sum(levels == 2))
message("  Level 3: ", sum(levels == 3))
