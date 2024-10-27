# TODO: work out how to get this functional
# https://github.com/Evidlo/remarkable_mouse
# (The binary/command exists, but the dependencies do not.)
{ config, pkgs, lib, ...}:
let 
  remouse = pkgs.python311Packages.buildPythonPackage rec {
    pname = "remarkable-mouse";
    version = "7.1.1";
    src = fetchPypi {
      inherit pname version;
      sha256 = "sha256-82P9tE3jiUlKBGZCiWDoL+9VJ06Bc+If+aMfcEEU90U=";
    };

    propagatedBuildInputs = [
      (pkgs.python311Packages.buildPythonPackage rec {
        pname = "paramiko";
        version = "3.5.0"; 
        src = lib.fetchPypi {
          pname = pname;
          version = version;
          sha256 = "sha256-rRHlQNpPVc7dpSkx8aP4Eqgjinr39ipg3lOM2AuygSQ="; 
        };
      })
    ];
  };
in
{
  home.packages = [
    remouse
  ];
}
