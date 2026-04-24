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
    hash = "sha256-1JILOIikJiAAluxIY+BGAqxSkw0WXBlpy73XMYnTwLU=";
  };

  vendorHash = "sha256-pZJA8TiYGlMMgH7JPiH+WUN7hNoL9wo/NWL9g+KhUL8=";

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
