{
  hull,
  pkgs,
  ...
}:
let
  # Problem letters follow this list order.
  problems = [
    ./problems/exampleSum/problem.nix
  ];
  common = problemTarget: hull.contestTarget.common { inherit problemTarget; };
in
{
  name = "contest";
  displayName.zh = "示例程序设计比赛";
  inherit problems;
  # One runtime analysis produces every package and the booklet.
  targets.default = {
    _type = "hullContestTarget";
    __functor =
      _: contest:
      pkgs.linkFarm "contest-${contest.name}" [
        {
          name = "internal";
          path = common "default" contest;
        }
        {
          name = "hydro";
          path = common "hydro" contest;
        }
        {
          name = "statements.pdf";
          path = (import ./nix/documents.nix { inherit hull pkgs; }).booklet contest problems;
        }
      ];
  };
}
