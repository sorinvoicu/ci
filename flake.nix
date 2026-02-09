{
  description = "R environment with .NET 8 for rSharp (FHS compatible)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        dotnet = pkgs.dotnet-sdk_8;

        # Common libraries needed by R packages
        libs = with pkgs; [
          # .NET and ICU
          dotnet
          icu

          # System dependencies
          curl
          openssl
          libxml2
          zlib

          # Graphics and font libraries
          libpng
          freetype
          fontconfig
          harfbuzz
          cairo
          libjpeg
          libtiff
          xorg.libX11
          xorg.libXt

          # Standard C library
          stdenv.cc.cc.lib
        ];

        # FHS environment that provides standard Linux paths
        fhsEnv = pkgs.buildFHSEnv {
          name = "r-fhs-env";
          targetPkgs = pkgs: with pkgs; [
            R
            gcc
            gnumake
            pkg-config
          ] ++ libs;

          profile = ''
            export DOTNET_ROOT="${dotnet}/share/dotnet"
            export DOTNET_CLI_TELEMETRY_OPTOUT=1
          '';
        };
      in
      {
        # FHS shell for running pre-built binaries (like ospsuite)
        devShells.default = pkgs.mkShell {
          buildInputs = [ fhsEnv ];

          shellHook = ''
            exec ${fhsEnv}/bin/r-fhs-env
          '';
        };

        # Also expose the FHS env directly
        packages.fhs = fhsEnv;
      }
    );
}
