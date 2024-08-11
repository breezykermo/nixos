set fish_greeting # disable greeting

# Important to ensure switching to fish_vi_key_bindings hasn't removed
# anything important
fish_default_key_bindings

zoxide init fish | source

# Necessary hack for environment variables
# See: https://github.com/nix-community/home-manager/issues/1011
set -gx DOOMDIR "$HOME/.doom.d"

# func disable_touchpad
# 	hyprctl keyword "device:tpps/2-elan-trackpoint:enabled" false
# 	hyprctl keyword "device:synaptics-tm3289-021:enabled" false
# end

# NPM packages go to home directory so as not to modify nix store
fish_add_path ~/.npm-packages/bin

# gpt-cli
if test -d "${config.home.homeDirectory}/.venvs/gpt-cli"
  set -x VIRTUAL_ENV ${config.home.homeDirectory}/.venvs/gpt-cli
  set -x PATH ${config.home.homeDirectory}/.venvs/gpt-cli/bin $PATH
  source ${config.home.homeDirectory}/.venvs/gpt-cli/bin/activate.fish
end

# direnv
direnv hook fish | source
