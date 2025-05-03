{
  description = "MVP headless browser scraper in Go";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.go
            pkgs.chromium
            pkgs.gcc
            pkgs.nodejs
            pkgs.golangci-lint
          ];

          shellHook = ''
            echo "Entering Go development environment"
            export GOBIN=$PWD/bin
            export PATH=$GOBIN:$PATH
          '';
        };
      });
}