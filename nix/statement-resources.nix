# Pinned template, font and Typst dependencies.
{ pkgs }:
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
in
{
  inherit olympInTypst foundertypeFonts;
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
    {
      name = "cetz";
      version = "0.4.2";
      hash = "sha256-qBIEHqtiMSG/WoXHPC/rQ9VkestSvVNlUwTmAMX1wAs=";
    }
    {
      name = "longops";
      version = "0.2.1";
      hash = "sha256-c11kTQqjcyTcX1EqCxY3IYTKvArbdukBEPeJ4tZXylY=";
    }
    {
      name = "zero";
      version = "0.7.0";
      hash = "sha256-+nvgzG2sV9sgf6z6fJZF/ssg9fceXf/jhEGDtmwpQ1I=";
    }
    {
      name = "mannot";
      version = "0.4.0";
      hash = "sha256-QrYztFl/QMDGkdqfz9jRXUlhHlY8gpgKR5tKWnjlWYY=";
    }
    {
      name = "oxifmt";
      version = "0.2.1";
      hash = "sha256-8PNPa9TGFybMZ1uuJwb5ET0WGIInmIgg8h24BmdfxlU=";
    }
    {
      name = "oxifmt";
      version = "1.0.0";
      hash = "sha256-edTDK5F2xFYWypGpR0dWxwM7IiBd8hKGQ0KArkbpHvI=";
    }
    {
      name = "pinit";
      version = "0.2.2";
      hash = "sha256-D7OwtnkPfyykCBrzpIM5naic13naxDmTxRRMe75su60=";
    }
    {
      name = "tiptoe";
      version = "0.4.0";
      hash = "sha256-awwCPfRXnAaUZ5w3NKt4K22JXzM4QRhTNGoNqrCoB8Q=";
    }
  ];
  fontPaths = [
    "${foundertypeFonts}"
    "${pkgs.newcomputermodern}/share/fonts/opentype/public"
    "${pkgs.cm_unicode}/share/fonts/opentype"
    "${pkgs.nerd-fonts.fira-code}/share/fonts/truetype/NerdFonts/FiraCode"
  ];
}
