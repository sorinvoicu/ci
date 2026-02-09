{
  description = "R environment with .NET for rSharp";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # R and common dependencies
            R

            # .NET SDK (latest)
            dotnet-sdk

            # System dependencies commonly needed for R packages
            curl
            openssl
            libxml2
            zlib
            pkg-config

            # For building R packages from source
            gcc
            gnumake
          ];

          shellHook = ''
            export DOTNET_ROOT="${pkgs.dotnet-sdk}"
            export DOTNET_CLI_TELEMETRY_OPTOUT=1
          '';
        };
      }
    );
}
