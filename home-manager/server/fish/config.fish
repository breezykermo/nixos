set fish_greeting # disable greeting

zoxide init fish | source

# Necessary hack for environment variables
# See: https://github.com/nix-community/home-manager/issues/1011
set -gx DOOMDIR "$HOME/.doom.d"
