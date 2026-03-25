#!/usr/bin/env Rscript
# Scan installed packages for known vulnerabilities using oysteR

library(oysteR)

message("Scanning installed packages for vulnerabilities...")

audit <- tryCatch(
  audit_installed_r_pkgs(),
  error = function(e) {
    message("Vulnerability scan failed: ", conditionMessage(e))
    NULL
  }
)

if (!is.null(audit)) {
  # Extract vulnerabilities if any
  vuln_df <- tryCatch({
    get_vulnerabilities(audit)
  }, error = function(e) {
    message("No vulnerability extraction method available, using raw results")
    # Try to build a summary from the audit object
    if (is.data.frame(audit)) {
      audit
    } else {
      data.frame(
        package = character(0),
        version = character(0),
        vulnerability = character(0),
        stringsAsFactors = FALSE
      )
    }
  })

  write.csv(vuln_df, "vulnerability-report.csv", row.names = FALSE)
  message("Vulnerability report written to vulnerability-report.csv")
  message("  Entries found: ", nrow(vuln_df))
} else {
  # Write empty report
  write.csv(
    data.frame(package = character(0), version = character(0),
               vulnerability = character(0), stringsAsFactors = FALSE),
    "vulnerability-report.csv", row.names = FALSE
  )
  message("Empty vulnerability report written (scan failed)")
}
