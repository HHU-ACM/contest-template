# Pinned Typst toolchain and the statement, editorial and booklet builders.
{ hull, pkgs }:
let
  olympInTypst = pkgs.fetchFromGitHub {
    owner = "lihaoze123";
    repo = "olymp-in-typst";
    rev = "3c82fe3dd4ce2540dec6bffcc7ce25f1f20947e6";
    hash = "sha256-grbZJtb303GZDUJ9V0hGLSRod5wWA8rto+1e3iTUdpw=";
  };
  foundertypeFont =
    name: hash:
    pkgs.fetchurl {
      url = "https://cdn1.foundertype.com/Public/Uploads/ttf/${name}";
      inherit hash;
      curlOptsList = [
        "--user-agent"
        "Mozilla/5.0"
      ];
    };
  foundertypeFonts = pkgs.linkFarm "foundertype-fonts" [
    {
      name = "FZSSK.TTF";
      path = foundertypeFont "FZSSK.TTF" "sha256-AP2/tDOq9MAN0Ct5MZu/6U/8o5nbob6eZFXku2UOAnM=";
    }
    {
      name = "FZHTK.TTF";
      path = foundertypeFont "FZHTK.TTF" "sha256-W+Y9vIZPBLAS+D21Oy4OpKLHAxHEpCzDPGIGrpzUfvA=";
    }
    {
      name = "FZXBSK.TTF";
      path = foundertypeFont "FZXBSK.TTF" "sha256-puTh7oh4uCS062bcWOJe0lWZLvOskBJkuERKW8WjACk=";
    }
  ];
  typstPackages = [
    {
      name = "numbly";
      version = "0.1.0";
      hash = "sha256-j3kolGf2gAJiXGymYpmtWiOJbtOvjQz8xxVjxKmjDQw=";
    }
    {
      name = "cmarker";
      version = "0.1.6";
      hash = "sha256-Rwbp3xfvtxX/0jEAaqQF5Ekg0RPe/bp9ZdqWdcrtoNM=";
    }
    {
      name = "mitex";
      version = "0.2.6";
      hash = "sha256-bSWz2OXgFasfFhGEzjzA/wtvafL9bjfqs8r3kC0sC9k=";
    }
  ];
  fontPaths = [
    "${foundertypeFonts}"
    "${pkgs.newcomputermodern}/share/fonts/opentype/public"
    "${pkgs.cm_unicode}/share/fonts/opentype"
    "${pkgs.nerd-fonts.fira-code}/share/fonts/truetype/NerdFonts/FiraCode"
  ];
  installLayout = entry: ''
    cp ${entry} $out/main.typ
    cp ${../documents/statement-common.typ} $out/statement-common.typ
    cp ${olympInTypst}/lib.typ $out/lib.typ
  '';
in
{
  statement =
    config: directory:
    hull.document.mkProblemTypstDocument config {
      src = pkgs.runCommandLocal "statement-${config.name}" { } ''
        mkdir $out
        cp -r --no-preserve=mode ${directory + "/document/statement"}/. $out/
        ${installLayout ../documents/problem.typ}
      '';
      inherit typstPackages fontPaths;
    };

  editorial =
    config: directory:
    hull.document.mkProblemTypstDocument config {
      src = directory + "/document/editorial";
      entry = "zh.typ";
      inherit fontPaths;
    };

  # Statements are addressed by list position, matching contest.problems.
  booklet =
    contest: problemPaths:
    hull.document.mkContestTypstDocument contest {
      src = pkgs.runCommandLocal "booklet-${contest.name}" { } ''
        mkdir -p $out/problems $out/illustrations
        ${pkgs.lib.concatImapStringsSep "\n" (
          index: path:
          let
            statement = dirOf path + "/document/statement";
          in
          ''
            cp -r --no-preserve=mode ${statement}/zh $out/problems/${toString (index - 1)}
            if [ -d ${statement}/illustrations ]; then
              cp -r --no-preserve=mode ${statement}/illustrations/. $out/illustrations/
            fi
          ''
        ) problemPaths}
        ${installLayout ../documents/contest.typ}
      '';
      inherit typstPackages fontPaths;
    };
}
