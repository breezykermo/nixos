{ 
  lib, 
  buildPythonPackage,
  python311Packages,
  fetchFromGitHub,
  fetchPypi,
}:
# TODO: work out how to get this functional
# https://github.com/Evidlo/remarkable_mouse
# (The binary/command exists, but the dependencies do not.)
let 
  remarkable_mouse = buildPythonPackage rec {
    pname = "remarkable-mouse";
    version = "7.1.1";
    src = fetchPypi {
      inherit pname version;
      sha256 = "sha256-82P9tE3jiUlKBGZCiWDoL+9VJ06Bc+If+aMfcEEU90U=";
    };

    propagatedBuildInputs = [
      (buildPythonPackage rec {
        pname = "paramiko";
        version = "3.5.0"; 
        src = fetchPypi {
          pname = pname;
          version = version;
          sha256 = "sha256-rRHlQNpPVc7dpSkx8aP4Eqgjinr39ipg3lOM2AuygSQ="; 
        };
      })
    ];
  };
in
  remarkable_mouse
# buildPythonPackage rec {
#   pname = "remarkable-mouse";
#   version = "7.1.0";
#   format = "pyproject";
#
#   src = fetchFromGitHub {
#     owner = "Evidlo";
#     repo = "remarkable_mouse";
#     rev = "v${version}"; 
#     # Get this hash via:  nix-prefetch-url --unpack https://github.com/kharvd/gpt-cli/archive/refs/tags/v0.2.0.tar.gz
#     sha256 = ""; 
#   };
#
#   nativeBuildInputs = with python311Packages; [
#     setuptools
#     wheel
#     pip
#   ];
#
#   propagatedBuildInputs = [
#     remarkable_mouse
#   ];
#
#   meta = with lib; {
#     description = "Remarkable as a wacom tablet";
#     homepage = "https://github.com/Evidlo/remarkable_mouse";
#     license = licenses.mit;
#     maintainers = [];
#   };
# }
