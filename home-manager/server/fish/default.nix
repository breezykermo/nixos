{ config, pkgs, lib, ...}:
{
    programs.fish = {
    enable = true;
    interactiveShellInit = ''
    set fish_greeting # disable greeting

    # Important to ensure switching to fish_vi_key_bindings hasn't removed
    # anything important
    fish_default_key_bindings

    zoxide init fish | source

    # Necessary hack for environment variables
    # See: https://github.com/nix-community/home-manager/issues/1011
    set -gx DOOMDIR "${config.home.homeDirectory}/.doom.d"

    # NPM packages go to home directory so as not to modify nix store
    fish_add_path ~/.npm-packages/bin

    # gpt-cli
    if test -d "${config.home.homeDirectory}/.venvs/gpt-cli"
      set -x VIRTUAL_ENV ${config.home.homeDirectory}/.venvs/gpt-cli
      set -x PATH ${config.home.homeDirectory}/.venvs/gpt-cli/bin $PATH
      source ${config.home.homeDirectory}/.venvs/gpt-cli/bin/activate.fish
    end
    '';

    plugins = [
      { name = "bass"; src = pkgs.fishPlugins.bass.src; }
    ];
  };
}

