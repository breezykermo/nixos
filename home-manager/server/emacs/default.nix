{ pkgs, ... }:
{

  programs.emacs = {
    enable = true; 
    package = pkgs.emacs;
    extraConfig = builtins.readFile ./config.el;
  };

  # programs.doom-emacs = {
  #   enable = true;
  #   doomPrivateDir = ./doom.d;
  # };
}
