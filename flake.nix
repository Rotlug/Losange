{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs@{
      nixpkgs,
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      flake.overlays.default = final: _prev: {
        losange = final.callPackage ./nix/package.nix { };
      };

      perSystem = { pkgs, ... }: {
        packages = rec {
          losange = pkgs.callPackage ./nix/package.nix { };
          default = losange;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            cargo
            rustc
            clippy
            rust-analyzer
            gcc
            pkg-config
            glib
            gtk4
            libadwaita
            mpv
            libepoxy
            nodejs
            ffmpeg
          ];

          shellHook = ''
            export GSETTINGS_SCHEMA_DIR="$PWD/.schemas"
            mkdir -p "$GSETTINGS_SCHEMA_DIR"
            cp data/xyz.timtimtim.Losange.gschema.xml "$GSETTINGS_SCHEMA_DIR/"
            glib-compile-schemas "$GSETTINGS_SCHEMA_DIR"
          '';
        };
      };
    };
}
