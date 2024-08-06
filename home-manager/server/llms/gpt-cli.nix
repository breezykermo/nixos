{ config, pkgs, ... }:

let
  virtualenv = pkgs.python3Packages.virtualenv;
  gptCliEnv = pkgs.writeShellScriptBin "gpt-cli-env" ''
    export VIRTUAL_ENV=${config.home.homeDirectory}/.venvs/gpt-cli
    export PATH="${config.home.homeDirectory}/.venvs/gpt-cli/bin:$PATH"
    if [ ! -d "$VIRTUAL_ENV" ]; then
      mkdir -p "$VIRTUAL_ENV"
      ${virtualenv}/bin/virtualenv "$VIRTUAL_ENV"
      $VIRTUAL_ENV/bin/pip install gpt-cli
    fi
  '';
in {
  home.sessionVariables = {
    VIRTUAL_ENV = "${config.home.homeDirectory}/.venvs/gpt-cli";
    PATH = "${config.home.homeDirectory}/.venvs/gpt-cli/bin:${config.home.sessionVariables.PATH}";
  };

  home.packages = with pkgs; [
    gptCliEnv
  ];
}

