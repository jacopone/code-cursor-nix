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
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages = {
          cursor = pkgs.callPackage ./package.nix { };
          default = self.packages.${system}.cursor;
        };

        # Development shell for testing
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            curl
            jq
            nix-prefetch
          ];
        };
      }
    );
}
