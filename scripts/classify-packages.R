#!/usr/bin/env Rscript
# Classify packages into intended_for_use, imports, and base categories

library(jsonlite)

packages <- readLines("r-packages.txt")
packages <- packages[packages != ""]

# Base and recommended packages
base_pkgs <- rownames(installed.packages(priority = "base"))
rec_pkgs <- rownames(installed.packages(priority = "recommended"))
base_and_rec <- c(base_pkgs, rec_pkgs)

# Resolve package names from GitHub refs
pkg_names <- vapply(packages, function(pkg) {
  result <- tryCatch(
    pak::pkg_deps(pkg, dependencies = FALSE)$package[1],
    error = function(e) {
      warning("Could not resolve package name for '", pkg, "': ", conditionMessage(e))
      NA_character_
    }
  )
  if (is.na(result)) {
    # Fall back to the last component of the ref (e.g. "Org/Repo@tag" -> "Repo")
    sub("@.*$", "", sub("^.*/", "", pkg))
  } else {
    result
  }
}, character(1))

# All intended-for-use packages start with the explicitly listed ones
intended <- unique(unname(pkg_names))

# Resolve full dependency tree for each package
all_imports <- character(0)

for (pkg in packages) {
  deps <- tryCatch(
    pak::pkg_deps(pkg),
    error = function(e) {
      warning("Could not resolve dependencies for '", pkg, "': ", conditionMessage(e))
      NULL
    }
  )
  if (is.null(deps)) next
  for (i in seq_len(nrow(deps))) {
    dep_name <- deps$package[i]
    dep_type <- deps$type[i]

    if (dep_name %in% base_and_rec) next
    if (dep_name %in% intended) next

    # Depends are promoted to intended_for_use
    if (!is.na(dep_type) && dep_type == "Depends") {
      intended <- c(intended, dep_name)
    } else {
      all_imports <- c(all_imports, dep_name)
    }
  }
}

intended <- unique(intended)
all_imports <- setdiff(unique(all_imports), intended)
all_imports <- setdiff(all_imports, base_and_rec)

# Build name -> GitHub ref mapping for intended-for-use packages
# (used by _setup.yml to construct the validate matrix)
pkg_ref_map <- setNames(as.list(packages), pkg_names)
intended_refs <- pkg_ref_map[names(pkg_ref_map) %in% intended]

classification <- list(
  intended_for_use = sort(intended),
  intended_for_use_refs = intended_refs,
  imports = sort(all_imports),
  base = sort(base_and_rec)
)

writeBin(charToRaw(enc2utf8(as.character(toJSON(classification, pretty = TRUE, auto_unbox = TRUE)))), "package-classification.json")
message("Package classification written to package-classification.json")
message("  Intended-for-use: ", length(classification$intended_for_use))
message("  Imports: ", length(classification$imports))
message("  Base/recommended: ", length(classification$base))
