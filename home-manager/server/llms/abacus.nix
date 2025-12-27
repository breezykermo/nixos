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
    hash = "sha256-EF/Hq16aKFKzfyhmRNxHB3saYQb/9h0XYKDZ3JPjDt8=";
  };

  vendorHash = "sha256-OU9obcFYv/jJj66RzKhRKO7ef2Gfl7l1JbwbL737y2k=";

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
