# Standalone booklet build: does not require running or judging all solutions.
{
  pkgs,
  typixLib,
  slug ? null,
}:
let
  resources = import ./statement-resources.nix { inherit pkgs; };
  source = pkgs.lib.cleanSourceWith {
    src = ../.;
    filter =
      path: type:
      let
        name = baseNameOf path;
      in
      !(builtins.elem name [
        ".git"
        ".build"
        ".hull"
        "result"
      ]);
  };
  preparedSource =
    pkgs.runCommandLocal "contest-statement-source"
      {
        nativeBuildInputs = [ pkgs.python3 ];
      }
      ''
        python ${source}/nix/prepare-statements.py --output $out ${
          pkgs.lib.optionalString (slug != null) "--single ${pkgs.lib.escapeShellArg slug}"
        }
        cp ${resources.olympInTypst}/lib.typ $out/lib.typ
      '';
in
typixLib.buildTypstProject {
  src = preparedSource;
  typstSource = "main.typ";
  typstOpts = pkgs.lib.optionalAttrs (slug != null) {
    input = [
      "language=zh"
      "hull-generated-json-path=problem.json"
    ];
  };
  inherit (resources) fontPaths;
  unstable_typstPackages = resources.typstPackages;
}
