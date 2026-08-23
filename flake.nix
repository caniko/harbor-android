{
  description = "Reusable Android SDK, NDK, and APK helpers for Nix flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    meta-harbor = {
      url = "git+https://github.com/caniko/meta-harbor.git?ref=trunk";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    flake-parts,
    self,
    nixpkgs,
    meta-harbor,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      flake = {
        lib = import ./lib {
          meta-harbor = meta-harbor.lib;
        };

        templates.default = {
          path = ./templates/default;
          description = "Android project with harbor-android";
        };
      };

      perSystem = {pkgs, ...}: {
        checks = import ./checks {
          inherit pkgs self;
          lib = self.lib;
        };

        formatter = pkgs.alejandra;
      };
    };
}
