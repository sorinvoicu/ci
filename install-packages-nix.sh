#!/usr/bin/env bash
# Install R packages from r-packages.txt using remotes (for Nix environment)

set -e

echo "Installing R packages from r-packages.txt using remotes..."

R --quiet --no-save << 'R_EOF'
packages <- readLines("r-packages.txt")
packages <- packages[packages != ""]

for (pkg in packages) {
  message("Installing: ", pkg, "@*release")
  # Get the latest release tag
  tryCatch({
    remotes::install_github(pkg, upgrade = "never", force = FALSE, ref = "*release")
  }, error = function(e) {
    message("Failed to install from release, trying default branch...")
    remotes::install_github(pkg, upgrade = "never", force = FALSE)
  })
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
