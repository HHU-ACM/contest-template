{ ... }:
{
  imports = [ (import ../../nix/problem.nix ./.) ];

  displayName.zh = "数列求和";
  tickLimit = 1000 * 10000000;
  memoryLimit = 256 * 1024 * 1024;

  generators.rand.src = ./generator/rand.23.cpp;
  testCases = {
    random1000 = {
      generator = "rand";
      arguments = [
        "--n=1000"
        "--bound=1000000000"
        "--mode=random"
        "--salt=official"
      ];
    };
    max1000 = {
      generator = "rand";
      arguments = [
        "--n=1000"
        "--bound=1000000000"
        "--mode=max"
        "--salt=official"
      ];
    };
  };

  validator.tests = {
    sample = {
      inputFile = ./data/samples/01.in;
      prediction = { status, ... }: status == "valid";
    };
    empty = {
      inputFile = builtins.toFile "sum-empty.in" "0\n\n";
      prediction = { status, ... }: status == "invalid";
    };
    outOfRange = {
      inputFile = builtins.toFile "sum-out-of-range.in" "1\n1000000001\n";
      prediction = { status, ... }: status == "invalid";
    };
    trailing = {
      inputFile = builtins.toFile "sum-trailing.in" "1\n1\nEXTRA\n";
      prediction = { status, ... }: status == "invalid";
    };
  };
  checker.tests = {
    sample = {
      inputFile = ./data/samples/01.in;
      outputFile = ./data/samples/01.out;
      prediction = { status, ... }: status == "accepted";
    };
    wrong = {
      inputFile = ./data/samples/01.in;
      outputFile = builtins.toFile "sum-wrong.out" "7\n";
      prediction = { status, ... }: status == "wrong_answer";
    };
    extraOutput = {
      inputFile = ./data/samples/01.in;
      outputFile = builtins.toFile "sum-extra.out" "6 EXTRA\n";
      prediction = { status, ... }: status == "wrong_answer";
    };
  };

  solutions = {
    std = {
      src = ./solution/std.20.cpp;
      mainCorrectSolution = true;
      subtaskPredictions."0" = { score, ... }: score == 1.0;
    };
    independent = {
      src = ./solution/independent.20.cpp;
      subtaskPredictions."0" = { score, ... }: score == 1.0;
    };
    wrongIgnoreLast = {
      src = ./solution/wrong_ignore_last.20.cpp;
      subtaskPredictions."0" = { statuses, ... }: builtins.elem "wrong_answer" statuses;
    };
  };
}
