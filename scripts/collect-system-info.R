#!/usr/bin/env Rscript
# Collect system information for validation traceability

library(jsonlite)

info <- list(
  timestamp = Sys.time(),
  r_version = list(
    version_string = R.version.string,
    major = R.version$major,
    minor = R.version$minor,
    platform = R.version$platform
  ),
  os = as.list(Sys.info()[c("sysname", "release", "version", "machine", "nodename")]),
  lib_paths = .libPaths(),
  locale = Sys.getlocale()
)

# .NET SDK version
dotnet_version <- tryCatch(
  trimws(system("dotnet --version", intern = TRUE)),
  error = function(e) NA_character_,
  warning = function(w) NA_character_
)
info$dotnet_version <- dotnet_version

# Installed packages summary
ip <- installed.packages()
info$installed_packages <- data.frame(
  package = ip[, "Package"],
  version = ip[, "Version"],
  stringsAsFactors = FALSE
)

# Chocolatey packages (Windows only)
if (.Platform$OS.type == "windows") {
  choco_list <- tryCatch({
    out <- system("choco list --local-only --limit-output", intern = TRUE)
    if (length(out) > 0) {
      parts <- strsplit(out, "\\|")
      data.frame(
        name = vapply(parts, `[`, character(1), 1),
        version = vapply(parts, `[`, character(1), 2),
        stringsAsFactors = FALSE
      )
    } else {
      NULL
    }
  }, error = function(e) NULL)
  info$chocolatey_packages <- choco_list
}

cat(as.character(toJSON(info, pretty = TRUE, auto_unbox = TRUE)), file = "system-info.json")
message("System info written to system-info.json")
