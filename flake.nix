{
  description = "R environment with .NET 8 for rSharp";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        dotnet = pkgs.dotnet-sdk_8;
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # R and common dependencies
            R

            # .NET 8 SDK (required by rSharp)
            dotnet

            # ICU for .NET globalization
            icu

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
            export DOTNET_ROOT="${dotnet}"
            export DOTNET_CLI_TELEMETRY_OPTOUT=1

            # Find and export hostfxr path for rSharp
            HOSTFXR_DIR=$(find ${dotnet}/host/fxr -maxdepth 1 -type d -name "[0-9]*" | head -1)
            RUNTIME_DIR=$(find ${dotnet}/shared/Microsoft.NETCore.App -maxdepth 1 -type d -name "[0-9]*" | head -1)

            export LD_LIBRARY_PATH="$HOSTFXR_DIR:$RUNTIME_DIR:${pkgs.icu}/lib:$LD_LIBRARY_PATH"
          '';
        };
      }
    );
}
