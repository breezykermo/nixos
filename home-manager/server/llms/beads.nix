{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "beads";
  version = "0.49.1";

  src = fetchFromGitHub {
    owner = "steveyegge";
    repo = "beads";
    rev = "2e6789d450784ef5e1290db22c627bb16dae0383";
    hash = "sha256-/1KGZE3uigQvQ3of7yfR9ilS+eZ29y7lBABGP1QMozE=";
  };

  vendorHash = "sha256-gwxGv8y4+1+k0741CnOYcyJPTJ5vTrynqPoO8YS9fbQ=";

  doCheck = false;

  ldflags = [ "-s" "-w" "-X main.version=${version}" ];

  meta = with lib; {
    description = "AI coding agent issue tracker";
    homepage = "https://github.com/steveyegge/beads";
    license = licenses.mit;
    mainProgram = "bd";
  };
}
