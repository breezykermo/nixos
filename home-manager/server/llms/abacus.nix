{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "abacus";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "ChrisEdwards";
    repo = "abacus";
    rev = "main";
    hash = "sha256-w5OWWGRa8IL9+G8XX071N4RTn7laYCOfLYquJn4+Gkw=";
  };

  vendorHash = "sha256-FnOq3c/wY1Kad9MbV3eV6yoiLu2L5Poe4AxF5nhzxlA=";

  ldflags = [
    "-s"
    "-w"
  ];

  subPackages = [ "cmd/abacus" ];

  meta = with lib; {
    description = "Terminal UI for visualizing and navigating Beads issue tracking projects";
    homepage = "https://github.com/ChrisEdwards/abacus";
    license = licenses.mit;
    maintainers = [ ];
    mainProgram = "abacus";
  };
}
