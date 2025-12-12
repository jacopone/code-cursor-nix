{
  description = "Auto-updating Nix package for Cursor - The AI Code Editor";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in
      {
        packages = {
          cursor = pkgs.callPackage ./package.nix { };
          default = self.packages.${system}.cursor;
        };

        apps = {
          default = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/cursor";
          };
          cursor = {
            type = "app";
            program = "${self.packages.${system}.cursor}/bin/cursor";
          };
        };

        # Development shell for contributors
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nix
            git
            curl
            jq
            gh
            nix-prefetch
          ];
        };
      }
    )
    // {
      # Overlay for NixOS integration
      overlays.default = final: prev: {
        cursor = final.callPackage ./package.nix { };
      };
    };
}
