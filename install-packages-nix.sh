#!/usr/bin/env bash
# Install R packages from r-packages.txt using remotes (for Nix environment)

set -e

echo "Installing R packages from r-packages.txt using remotes..."

R --quiet --no-save << 'R_EOF'
packages <- readLines("r-packages.txt")
packages <- packages[packages != ""]

# Function to get latest release tag from GitHub API
get_latest_release <- function(repo) {
  url <- sprintf("https://api.github.com/repos/%s/releases/latest", repo)
  tryCatch({
    response <- readLines(url, warn = FALSE)
    json <- paste(response, collapse = "")
    # Extract tag_name from JSON
    match <- regmatches(json, regexpr('"tag_name"\\s*:\\s*"[^"]+"', json))
    if (length(match) > 0) {
      tag <- gsub('.*"tag_name"\\s*:\\s*"([^"]+)".*', "\\1", match)
      return(tag)
    }
  }, error = function(e) NULL)
  return(NULL)
}

for (pkg in packages) {
  message("Installing: ", pkg)

  # Try to get latest release tag
  release_tag <- get_latest_release(pkg)

  if (!is.null(release_tag)) {
    message("  Using release: ", release_tag)
    tryCatch({
      remotes::install_github(pkg, ref = release_tag, upgrade = "never", force = FALSE)
    }, error = function(e) {
      message("  Failed with release tag, trying default branch...")
      remotes::install_github(pkg, upgrade = "never", force = FALSE)
    })
  } else {
    message("  No release found, using default branch")
    remotes::install_github(pkg, upgrade = "never", force = FALSE)
  }
}

message("\n✓ All packages installed successfully!")
message("\nInstalled GitHub packages:")
installed <- installed.packages()
github_pkgs <- c("rSharp", "ospsuite", "tlf", "ospsuite.utils",
                 "ospsuite.parameteridentification", "esqlabsR")
for (pkg in github_pkgs) {
  if (pkg %in% installed[, "Package"]) {
    message(sprintf("  - %s %s", pkg, installed[pkg, "Version"]))
  }
}
R_EOF

echo "Done!"
