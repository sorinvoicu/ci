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

            # Graphics and font libraries (needed for sysfonts, showtext, etc.)
            libpng
            freetype
            fontconfig
            harfbuzz
            cairo
            libjpeg
            libtiff

            # For building R packages from source
            gcc
            gnumake
          ];

          shellHook = ''
            # The actual dotnet runtime is under share/dotnet in the SDK package
            export DOTNET_ROOT="${dotnet}/share/dotnet"
            export DOTNET_CLI_TELEMETRY_OPTOUT=1

            # Find and export hostfxr path for rSharp
            HOSTFXR_DIR=$(find $DOTNET_ROOT/host/fxr -maxdepth 1 -type d -name "[0-9]*" 2>/dev/null | head -1)
            RUNTIME_DIR=$(find $DOTNET_ROOT/shared/Microsoft.NETCore.App -maxdepth 1 -type d -name "[0-9]*" 2>/dev/null | head -1)

            export LD_LIBRARY_PATH="$HOSTFXR_DIR:$RUNTIME_DIR:${pkgs.icu}/lib:$LD_LIBRARY_PATH"
          '';
        };
      }
    );
}
