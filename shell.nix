{ pkgs ? import <nixpkgs> {} }:

let
  # System dependencies mapped to Nix packages
  systemDeps = with pkgs; [
    dotnet-runtime_8
    curl.dev
    openssl.dev
    libxml2.dev
    fontconfig.dev
    harfbuzz.dev
    fribidi.dev
    freetype.dev
    libpng.dev
    libtiff.dev
    libjpeg.dev
  ];

  # R with basic packages
  rEnv = pkgs.rWrapper.override {
    packages = with pkgs.rPackages; [
      pak
      renv
    ];
  };

in pkgs.mkShell {
  name = "esqlabs-r-environment";

  buildInputs = [
    rEnv
    pkgs.git
    pkgs.which
    pkgs.curl
  ] ++ systemDeps;

  shellHook = ''
    echo "================================================"
    echo "ESQlabs R Environment (Nix Shell)"
    echo "================================================"
    echo "R version: $(R --version | head -1)"
    echo ""
    echo "To install GitHub packages, run:"
    echo "  R -e 'pak::pak(readLines(\"r-packages.txt\")[-length(readLines(\"r-packages.txt\"))])'"
    echo ""
    echo "Or install with released versions:"
    echo "  R -e 'pkgs <- readLines(\"r-packages.txt\"); pkgs <- pkgs[pkgs != \"\"]; for(p in pkgs) pak::pak(paste0(p, \"@*release\"))'"
    echo "================================================"
  '';
}
