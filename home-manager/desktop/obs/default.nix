{
  config,
  lib,
  pkgs,
  ...
}: let
  # Switches OBS's active scene. One argument switches straight to that scene;
  # several step to the next name in the list and wrap, so two names give an
  # A<->B toggle. Connection details are read out of obs-websocket's own config
  # file, which OBS rewrites whenever the port or password changes in
  # Tools -> WebSocket Server Settings, so there is nothing to keep in sync here.
  obs-scene = pkgs.writeShellApplication {
    name = "obs-scene";
    runtimeInputs = [pkgs.obs-cmd pkgs.jq];
    text = ''
      if [ "$#" -lt 1 ]; then
        echo "usage: obs-scene <scene> [scene...]" >&2
        exit 64
      fi

      cfg="''${XDG_CONFIG_HOME:-$HOME/.config}/obs-studio/plugin_config/obs-websocket/config.json"
      if [ ! -r "$cfg" ]; then
        echo "obs-scene: no obs-websocket config at $cfg (is OBS running?)" >&2
        exit 69
      fi

      port=$(jq -r '.server_port // 4455' "$cfg")
      password=$(jq -r '.server_password // ""' "$cfg")
      url="obsws://localhost:$port/$password"

      current=$(obs-cmd --websocket "$url" scene current | sed 's/^Current scene: //')

      # Find the current scene in the argument list and pick the one after it.
      # An unknown current scene falls through to the first argument.
      next="$1"
      i=1
      for scene in "$@"; do
        if [ "$scene" = "$current" ]; then
          if [ "$i" -lt "$#" ]; then
            shift "$i"
            next="$1"
          fi
          break
        fi
        i=$((i + 1))
      done

      exec obs-cmd --websocket "$url" scene switch "$next"
    '';
  };
in {
  config = lib.mkIf config.custom.homework {
    home.packages = with pkgs; [
      vlc
      obs-cmd
      obs-scene
    ];

    programs.obs-studio = {
      enable = true;
      # see https://mynixos.com/packages/obs-studio-plugins
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        droidcam-obs
        obs-composite-blur
        obs-move-transition
        obs-backgroundremoval
        obs-pipewire-audio-capture
      ];
    };
  };
}
