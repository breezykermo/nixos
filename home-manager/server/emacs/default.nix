{ lib, pkgs, ... }:
{
  environment.sessionVariables = rec {
   DOOMDIR = "$HOME/nixos-config/home-manager/server/emacs/doom.d";
  };

  programs.emacs = {
    enable = true; 
    package = pkgs.emacs;
    # extraConfig = builtins.readFile ./config.el;
  };

# https://github.com/nix-community/nix-doom-emacs is broken ATM.
# There is almost certainly a way to do this;
# but currently I don't have a better way to automate this: so for each fresh install:
# so just install doom manually.

#   git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
#   ~/.config/emacs/bin/doom install 
#   ~/.config/emacs/bin/doom sync

}
