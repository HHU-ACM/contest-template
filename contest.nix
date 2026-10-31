{
  hull,
  pkgs ? null,
  ...
}:
{
  name = "contest";
  displayName.zh = "示例程序设计比赛";
  # Problem letters follow this list order.
  problems = [
    ./problems/example-sum/problem.nix
  ];
  targets = {
    default = hull.contestTarget.common { problemTarget = "default"; };
    hydro = hull.contestTarget.common { problemTarget = "hydro"; };
    # Build both package formats from one runtime analysis.
    ci = {
      _type = "hullContestTarget";
      __functor =
        self: contest:
        pkgs.linkFarm "contest-ci" [
          {
            name = "internal";
            path = contest.targets.default contest;
          }
          {
            name = "hydro";
            path = contest.targets.hydro contest;
          }
        ];
    };
  };
}
