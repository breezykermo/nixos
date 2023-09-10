{ pkgs, lib, ...}:
{
	programs.fish = {
    enable = true;
    interactiveShellInit = builtins.readFile ./config.fish;
    plugins = [
      { name = "bass"; src = pkgs.fishPlugins.bass.src; }
    ];
  };
}

