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
      remotes
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
    echo "System dependencies: installed"
    echo "R packages (remotes, renv): installed"
    echo ""
    echo "To install GitHub packages, run:"
    echo "  ./install-packages-nix.sh"
    echo ""
    echo "Or manually:"
    echo "  R -e 'pkgs <- readLines(\"r-packages.txt\"); pkgs <- pkgs[pkgs != \"\"]; for(p in pkgs) remotes::install_github(p, upgrade=\"never\")'"
    echo "================================================"
  '';
}
