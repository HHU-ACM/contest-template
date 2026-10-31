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
      # contest.nix owns the problem list and its order.
      problemPaths = builtins.listToAttrs (
        map (path: {
          name = baseNameOf (dirOf path);
          value = path;
        }) (import ./contest.nix { hull = null; }).problems
      );
    in
    {
      hullProblems = eachSystem (
        system: builtins.mapAttrs (_: path: hull.lib.${system}.evalProblem path { }) problemPaths
      );
      hullContests = eachSystem (system: {
        default = hull.lib.${system}.evalContest ./contest.nix { };
      });
      packages = eachSystem (system: {
        statement-previews = nixpkgs.legacyPackages.${system}.linkFarm "statement-previews" (
          map (slug: {
            name = "${slug}.pdf";
            path = import ./nix/contest-statement.nix {
              pkgs = nixpkgs.legacyPackages.${system};
              typixLib = hull.inputs.typix.lib.${system};
              inherit slug;
            };
          }) (builtins.attrNames problemPaths)
        );
        contest-statements = import ./nix/contest-statement.nix {
          pkgs = nixpkgs.legacyPackages.${system};
          typixLib = hull.inputs.typix.lib.${system};
        };
      });
      devShells = eachSystem (system: {
        default = nixpkgs.legacyPackages.${system}.mkShell {
          packages = [
            hull.packages.${system}.default
            nixpkgs.legacyPackages.${system}.python3
            nixpkgs.legacyPackages.${system}.gcc
            nixpkgs.legacyPackages.${system}.just
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
