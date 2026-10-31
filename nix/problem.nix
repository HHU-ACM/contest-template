{
  directory,
  name,
  title,
  timeLimitMs,
  memoryLimitMb,
  solutions,
  invalidInput,
  generators ? { },
  extraValidatorTests ? { },
  extraCheckerTests ? { },
  extraTestCases ? { },
}:
{
  hull,
  pkgs,
  lib,
  config,
  cplib,
  ...
}:
let
  readCases =
    group: folder:
    lib.mapAttrs'
      (file: _: {
        name = "${group}${lib.removeSuffix ".in" file}";
        value = {
          inputFile = directory + "/data/${folder}/${file}";
          groups = lib.optional (group == "sample") "sample";
        };
      })
      (
        lib.filterAttrs (file: kind: kind == "regular" && lib.hasSuffix ".in" file) (
          builtins.readDir (directory + "/data/${folder}")
        )
      );
in
{
  inherit name solutions generators;
  displayName.zh = title;
  tickLimit = timeLimitMs * 10000000;
  memoryLimit = memoryLimitMb * 1024 * 1024;
  authoringIncludes = [
    cplib
    ../authoring-include
    (directory + "/authoring-include")
  ];
  validator = {
    src = directory + "/validator.23.cpp";
    tests = {
      sample = {
        inputFile = directory + "/data/samples/01.in";
        prediction = { status, ... }: status == "valid";
      };
      invalid = {
        inputFile = builtins.toFile "${name}-invalid.in" invalidInput;
        prediction = { status, ... }: status == "invalid";
      };
      trailing = {
        inputFile = builtins.toFile "${name}-trailing.in" (
          (builtins.readFile (directory + "/data/samples/01.in")) + "EXTRA\n"
        );
        prediction = { status, ... }: status == "invalid";
      };
    }
    // extraValidatorTests;
  };
  checker = {
    src = directory + "/checker.23.cpp";
    tests = {
      sample = {
        inputFile = directory + "/data/samples/01.in";
        outputFile = directory + "/data/samples/01.out";
        prediction = { status, ... }: status == "accepted";
      };
      extraOutput = {
        inputFile = directory + "/data/samples/01.in";
        outputFile = builtins.toFile "${name}-extra.out" (
          (builtins.readFile (directory + "/data/samples/01.out")) + " EXTRA\n"
        );
        prediction = { status, ... }: status == "wrong_answer";
      };
    }
    // extraCheckerTests;
  };
  testCases = (readCases "sample" "samples") // (readCases "test" "tests") // extraTestCases;
  # Samples precede test cases; scores are summed across cases.
  subtasks = [
    {
      fullScore = 1.0;
      scoringMethod = "sum";
    }
  ];
  documents = {
    "statement.zh.pdf" = {
      path = import ./statement.nix {
        inherit hull pkgs config;
        src = directory + "/document/statement";
      };
      displayLanguage = "zh";
      participantVisibility = true;
    };
  }
  // lib.optionalAttrs (builtins.pathExists (directory + "/document/editorial/zh.typ")) {
    "editorial.zh.pdf" = {
      path = import ./editorial.nix {
        inherit hull pkgs config;
        src = directory + "/document/editorial";
      };
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
      testDataExtraFiles."normalized_text.23.hpp" = ../authoring-include/normalized_text.23.hpp;
      judgeExtraFiles = [
        "problem.23.hpp"
        "normalized_text.23.hpp"
      ];
    };
  };
}
