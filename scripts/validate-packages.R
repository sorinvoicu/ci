#!/usr/bin/env Rscript
# Run R CMD check and covr on intended-for-use packages

library(jsonlite)
library(rcmdcheck)
library(covr)

classification <- fromJSON("package-classification.json")
pkg_lines <- readLines("r-packages.txt")
pkg_lines <- pkg_lines[pkg_lines != ""]

# When TARGET_PACKAGE + TARGET_REF are set (matrix CI job), use them directly —
# avoids re-resolving all package names via network before results are populated.
# Fall back to building pkg_map from pak when running locally / without TARGET_REF.
target_pkg <- Sys.getenv("TARGET_PACKAGE", "")
target_ref <- Sys.getenv("TARGET_REF", "")

if (nchar(target_pkg) > 0 && nchar(target_ref) > 0) {
  pkg_map <- setNames(list(target_ref), target_pkg)
} else {
  pkg_map <- list()
  for (line in pkg_lines) {
    pkg_name <- tryCatch(
      pak::pkg_deps(line, dependencies = FALSE)$package[1],
      error = function(e) {
        warning("Could not resolve package name for '", line, "': ", conditionMessage(e))
        sub("@.*$", "", sub("^.*/", "", line))
      }
    )
    pkg_map[[pkg_name]] <- line
  }
}

pkgs_to_validate <- if (nchar(target_pkg) > 0) target_pkg else classification$intended_for_use
output_file <- if (nchar(target_pkg) > 0) paste0("validation-", target_pkg, ".json") else "validation-results.json"

results <- list()

# on.exit() at the top level of source() fires immediately (per eval expression),
# not when the script finishes. Use tryCatch/finally instead to ensure results are
# written after the loop completes, even on unexpected errors.
tryCatch({

for (pkg_name in pkgs_to_validate) {
  message("\n=== Validating: ", pkg_name, " ===")

  github_ref <- pkg_map[[pkg_name]]
  if (is.null(github_ref)) {
    message("  Skipping ", pkg_name, " — not a direct GitHub package (likely a promoted Depends)")
    results[[pkg_name]] <- list(
      package = pkg_name,
      source = "dependency",
      rcmdcheck = "SKIPPED",
      coverage_pct = NA,
      git_sha = NA,
      notes = "Promoted from Depends; no direct GitHub source in r-packages.txt"
    )
    next
  }

  # Parse owner/repo@tag
  parts <- strsplit(github_ref, "@")[[1]]
  repo_path <- parts[1]
  tag <- if (length(parts) > 1) parts[2] else "HEAD"

  clone_dir <- file.path(tempdir(), pkg_name)
  if (dir.exists(clone_dir)) unlink(clone_dir, recursive = TRUE)

  # Clone at pinned tag
  clone_url <- paste0("https://github.com/", repo_path, ".git")
  message("  Cloning ", clone_url, " at ", tag)

  clone_out <- system2("git", c("clone", "--depth", "1", "--branch", tag, clone_url, clone_dir),
                       stdout = TRUE, stderr = TRUE)
  clone_ok <- is.null(attr(clone_out, "status")) || attr(clone_out, "status") == 0L

  if (!clone_ok) {
    message("  Clone failed (exit status ", attr(clone_out, "status"), ")")
    results[[pkg_name]] <- list(
      package = pkg_name,
      source = github_ref,
      rcmdcheck = "CLONE_FAILED",
      coverage_pct = NA,
      git_sha = NA,
      notes = paste(clone_out, collapse = "\n")
    )
    next
  }

  # Get git SHA
  git_sha <- tryCatch(
    trimws(system2("git", c("-C", clone_dir, "rev-parse", "HEAD"), stdout = TRUE)),
    error = function(e) NA_character_
  )

  # R CMD check
  message("  Running R CMD check...")
  check_result <- tryCatch({
    res <- rcmdcheck(clone_dir,
                     args = c("--no-manual", "--no-vignettes"),
                     build_args = "--no-build-vignettes",
                     env = c(rcmdcheck_env(), "_R_CHECK_FORCE_SUGGESTS_" = "false"),
                     quiet = TRUE, error_on = "never")
    status <- if (length(res$errors) > 0) {
      "ERROR"
    } else if (length(res$warnings) > 0) {
      "WARNING"
    } else if (length(res$notes) > 0) {
      "NOTE"
    } else {
      "PASS"
    }
    list(
      status = status,
      errors = res$errors,
      warnings = res$warnings,
      notes = res$notes
    )
  }, error = function(e) {
    list(status = "ERROR", errors = conditionMessage(e), warnings = character(0), notes = character(0))
  })
  message("  R CMD check: ", check_result$status)

  # Coverage
  message("  Running covr...")
  cov_pct <- tryCatch({
    cov <- package_coverage(clone_dir, quiet = TRUE, lib = .libPaths())
    as.numeric(percent_coverage(cov))
  }, error = function(e) {
    message("  Coverage failed: ", conditionMessage(e))
    NA_real_
  })
  if (!is.na(cov_pct)) message("  Coverage: ", round(cov_pct, 1), "%")

  results[[pkg_name]] <- list(
    package = pkg_name,
    source = github_ref,
    git_sha = git_sha,
    rcmdcheck = check_result$status,
    rcmdcheck_errors = check_result$errors,
    rcmdcheck_warnings = check_result$warnings,
    rcmdcheck_notes = check_result$notes,
    coverage_pct = cov_pct
  )

  # Cleanup
  unlink(clone_dir, recursive = TRUE)
}

}, finally = {
  writeBin(charToRaw(enc2utf8(as.character(toJSON(results, pretty = TRUE, auto_unbox = TRUE)))), output_file)
  message("\nValidation results written to ", output_file)
})
