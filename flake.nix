{
  description = "Reusable contest authoring template powered by Hull";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cplib = {
      url = "github:rindag-devs/cplib/single-header-snapshot";
      flake = false;
    };
    hull = {
      url = "github:rindag-devs/hull";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.cplib.follows = "cplib";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
      hull,
      cplib,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      eachSystem = nixpkgs.lib.genAttrs systems;
      contests = eachSystem (system: hull.lib.${system}.evalContest ./contest.nix { });
    in
    {
      # contest.nix owns the problem list and its order.
      hullProblems = eachSystem (
        system:
        builtins.listToAttrs (
          map (problem: {
            inherit (problem.config) name;
            value = problem;
          }) contests.${system}.config.problems
        )
      );
      hullContests = eachSystem (system: {
        default = contests.${system};
      });
      devShells = eachSystem (system: {
        default = nixpkgs.legacyPackages.${system}.mkShell {
          packages = [
            hull.packages.${system}.default
          ];
          CPLUS_INCLUDE_PATH = toString cplib;
        };
      });
      formatter = eachSystem (
        system:
        (treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} {
          projectRootFile = "flake.nix";
          programs = {
            clang-format.enable = true;
            nixfmt.enable = true;
            typstyle.enable = true;
          };
          # Vendored agent skills are managed by skills-lock.json.
          settings.global.excludes = [
            ".agents/**"
            ".claude/**"
          ];
        }).config.build.wrapper
      );
    };
}
