# Shared olymp-in-typst statement builder.
{
  hull,
  pkgs,
  config,
  src,
}:
let
  resources = import ./statement-resources.nix { inherit pkgs; };
  statementSrc = pkgs.runCommandLocal "hull-olympStatement-${config.name}" { } ''
    mkdir $out
    cp -r ${src}/. $out/
    cp ${../documents/problem-main.typ} $out/main.typ
    cp ${../documents/statement-common.typ} $out/statement-common.typ
    cp ${resources.olympInTypst}/lib.typ $out/lib.typ
  '';
in
hull.document.mkProblemTypstDocument config {
  src = statementSrc;
  inputs.language = "zh";
  inherit (resources) typstPackages fontPaths;
}
