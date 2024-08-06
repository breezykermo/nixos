{ pkgs, lib, ...}:
let 
  gptCli = import ./gpt-cli.nix { 
    inherit (pkgs) lib fetchPypi;
    inherit (pkgs.python311Packages) buildPythonPackage;
    inherit (pkgs) python311Packages;
  }; 
in
{
  home.packages = with pkgs; [
    gptCli
  ];
}
