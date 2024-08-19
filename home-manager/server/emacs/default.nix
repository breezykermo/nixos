{ lib, pkgs, ... }:
{

  # user.sessionVariables.DOOMDIR = "$HOME/.doom.d";
  programs.emacs = {
    enable = true; 
    package = pkgs.emacs;
    # extraConfig = builtins.readFile ./config.el;
  };

  home.file.".doom.d" = {
    source = ./doom.d;
    recursive = true;
  };

# TODO: https://github.com/nix-community/nix-doom-emacs is broken ATM.
# There is almost certainly a way to do this;
# but currently I don't have a better way to automate this: so for each fresh install:
# I need to just install doom manually:

#   git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
#   ~/.config/emacs/bin/doom install 
#   ~/.config/emacs/bin/doom sync

# See https://github.com/yrashk/nix-home/blob/master/home.nix#L379-L389
# for an example of how to just git clone a doomemacs revision automatically.
}
