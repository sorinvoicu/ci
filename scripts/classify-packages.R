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
  pak::pkg_deps(pkg, dependencies = FALSE)$package[1]
}, character(1))

# All intended-for-use packages start with the explicitly listed ones
intended <- unique(unname(pkg_names))

# Resolve full dependency tree for each package
all_imports <- character(0)

for (pkg in packages) {
  deps <- pak::pkg_deps(pkg)
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

classification <- list(
  intended_for_use = sort(intended),
  imports = sort(all_imports),
  base = sort(base_and_rec)
)

write_json(classification, "package-classification.json", pretty = TRUE, auto_unbox = TRUE)
message("Package classification written to package-classification.json")
message("  Intended-for-use: ", length(classification$intended_for_use))
message("  Imports: ", length(classification$imports))
message("  Base/recommended: ", length(classification$base))
