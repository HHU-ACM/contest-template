import ../../nix/problem.nix {
  directory = ./.;
  name = "exampleSum";
  title = "数列求和";
  timeLimitMs = 1000;
  memoryLimitMb = 256;
  invalidInput = "0\n\n";
  generators.rand.src = ./generator/rand.23.cpp;
  extraValidatorTests.outOfRange = {
    inputFile = builtins.toFile "sum-invalid-value.in" "1\n1000000001\n";
    prediction = { status, ... }: status == "invalid";
  };
  extraCheckerTests.wrong = {
    inputFile = ./data/samples/01.in;
    outputFile = builtins.toFile "sum-wrong.out" "7\n";
    prediction = { status, ... }: status == "wrong_answer";
  };
  extraTestCases = builtins.listToAttrs (
    builtins.concatMap
      (
        mode:
        map
          (n: {
            name = "${mode}${toString n}";
            value = {
              generator = "rand";
              arguments = [
                "--n=${toString n}"
                "--bound=1000000000"
                "--mode=${mode}"
                "--salt=official"
              ];
            };
          })
          [
            1
            17
            1000
          ]
      )
      [
        "random"
        "min"
        "max"
        "alternating"
        "zeros"
      ]
  );
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
