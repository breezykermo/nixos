# NOTE: I am not using any LLM software natively at the moment, thus all here
# is commented out. But I would ultimately like to have a TUI interface for
# them, to stay within the terminal as much as possible.
{ pkgs,  ...}:
let 
  # gptCli = import ./gpt-cli.nix { 
  #   inherit (pkgs) lib fetchFromGitHub python311Packages fetchPypi;
  #   inherit (pkgs.python311Packages) buildPythonPackage;
  # }; 

  remouse = import ./remouse.nix {
    inherit (pkgs) lib fetchFromGitHub python311Packages fetchPypi;
    inherit (pkgs.python311Packages) buildPythonPackage;
  };
in
{
  home.packages = [
    # gptCli
    remouse
  ];
}
