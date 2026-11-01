# Shared defaults for a batch problem; problem.nix can override any of them.
directory:
{
  hull,
  pkgs,
  lib,
  config,
  cplib,
  ...
}:
let
  documents = import ./documents.nix { inherit hull pkgs; };
  readCases =
    prefix: folder: groups:
    let
      path = directory + "/data/${folder}";
      inputs = lib.filterAttrs (file: _: lib.hasSuffix ".in" file) (
        lib.optionalAttrs (builtins.pathExists path) (builtins.readDir path)
      );
    in
    lib.mapAttrs' (file: _: {
      name = "${prefix}${lib.removeSuffix ".in" file}";
      value = {
        inputFile = path + "/${file}";
        inherit groups;
      };
    }) inputs;
in
{
  name = lib.mkDefault (baseNameOf directory);
  authoringIncludes = [
    cplib
    (directory + "/authoring-include")
  ];
  validator.src = lib.mkDefault (directory + "/validator.23.cpp");
  checker.src = lib.mkDefault (directory + "/checker.23.cpp");
  testCases = readCases "sample" "samples" [ "sample" ] // readCases "test" "tests" [ ];
  # Samples precede test cases; scores are summed across cases.
  subtasks = lib.mkDefault [
    {
      fullScore = 1.0;
      scoringMethod = "sum";
    }
  ];
  documents = {
    "statement.zh.pdf" = {
      path = documents.statement config directory;
      displayLanguage = "zh";
      participantVisibility = true;
    };
    "editorial.zh.pdf" = {
      path = documents.editorial config directory;
      displayLanguage = "zh";
      participantVisibility = false;
    };
  };
  targets = {
    default = hull.problemTarget.common;
    hydro = hull.problemTarget.legacy.hydro.batch {
      statements.zh = "statement.zh.pdf";
      defaultDisplayLanguage = "zh";
      testDataExtraFiles."problem.23.hpp" = directory + "/authoring-include/problem.23.hpp";
      judgeExtraFiles = [ "problem.23.hpp" ];
    };
  };
}
