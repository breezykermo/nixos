{ pkgs, lib, ...}:
{
	programs.fish = {
    enable = true;
    interactiveShellInit = builtins.readFile ./fish.config;
  };
}

