{ pkgs, poetry2nix, ...}:
let 
  gptCli = import ./gpt-cli.nix { 
    inherit (pkgs) lib fetchFromGitHub;
    inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; }) mkPoetryApplication;
  }; 
in
{
  home.packages = [
    gptCli
  ];
}
