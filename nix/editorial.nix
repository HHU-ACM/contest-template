# Private editorials use the same pinned fonts as problem statements.
{
  hull,
  pkgs,
  config,
  src,
}:
let
  resources = import ./statement-resources.nix { inherit pkgs; };
  editorialSrc = pkgs.runCommandLocal "hull-editorial-${config.name}" { } ''
    mkdir $out
    cp ${src}/zh.typ $out/main.typ
  '';
in
hull.document.mkProblemTypstDocument config {
  src = editorialSrc;
  inherit (resources) fontPaths;
}
