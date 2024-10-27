{ pkgs,  ...}:
let 
  gptCli = import ./gpt-cli.nix { 
    inherit (pkgs) lib fetchFromGitHub python311Packages fetchPypi;
    inherit (pkgs.python311Packages) buildPythonPackage;
  }; 
in
{
  home.packages = [
    # gptCli
  ];
}
