set fish_greeting # disable greeting

zoxide init fish | source

# Necessary hack for environment variables
# See: https://github.com/nix-community/home-manager/issues/1011
set -gx DOOMDIR "$HOME/.doom.d"

# Hack for Thinkpad. TODO how do I localise this?
# func disable_touchpad
# 	hyprctl keyword "device:tpps/2-elan-trackpoint:enabled" false
# 	hyprctl keyword "device:synaptics-tm3289-021:enabled" false
# end
