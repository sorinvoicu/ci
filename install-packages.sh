#!/usr/bin/env bash
# Install R packages from r-packages.txt

set -e

echo "Installing R packages from r-packages.txt..."

R --quiet --no-save << 'R_EOF'
packages <- readLines("r-packages.txt")
packages <- packages[packages != ""]

for (pkg in packages) {
  pkg_release <- paste0(pkg, "@*release")
  message("Installing: ", pkg_release)
  pak::pak(pkg_release)
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
