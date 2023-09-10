{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.gui.waybar;
in {
  options.gui.waybar = with lib; {
    enable = mkEnableOption "waybar status bar";

    modules = {
      label = mkOption {
        type = types.str;
        description = "system label";
      };

      volume.enable = mkEnableOption "volume module";
      brightness.enable = mkEnableOption "brightness module";
      battery.enable = mkEnableOption "battery module";

      cpu.temperaturePath = mkOption {
        type = types.str;
        description = "cpu temperature filesystem path";
      };

      gpu = {
        enable = mkEnableOption "gpu module";
        usagePath = mkOption {
          type = types.str;
          description = "gpu filesystem path";
        };

        temperaturePath = mkOption {
          type = types.str;
          description = "gpu temperature filesystem path";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.waybar = {
      enable = true;

      package = pkgs.waybar.override {
        # Rip out things I don't use
        cavaSupport = false;
        jackSupport = false;
        mpdSupport = false;
        pulseSupport = false;
        sndioSupport = false;
        swaySupport = false;
        traySupport = false;
        upowerSupport = false;
        withMediaPlayer = false;
      };

      settings = [
        {
          layer = "top";
          position = "top";
          height = 24;

          margin-left = 16;
          margin-right = 16;

          modules-left = [
            "custom/label"
            "hyprland/workspaces"
            "hyprland/window"
          ];

          modules-center =
            lib.optional cfg.modules.volume.enable "wireplumber"
            ++ lib.optional cfg.modules.brightness.enable "backlight"
            ++ lib.optional cfg.modules.battery.enable "battery"
            ++ ["cpu" "temperature" "memory"]
            ++ lib.optionals cfg.modules.gpu.enable ["custom/gpu" "custom/gpu-temp"]
            ++ ["disk"];

          modules-right = ["mpris" "clock#date" "clock"];

          "custom/label" = {
            format = cfg.modules.label;
          };

          cpu = {
            interval = 1;
            format = "CPU:{usage:>3}% {avg_frequency:.1f}GHz";
          };
          temperature = {
            hwmon-path = cfg.modules.cpu.temperaturePath;
            interval = 1;
            critical-threshold = 70;
            format = "{temperatureC:>3}°C";
          };

          memory = {
            interval = 1;
            format = "RAM:{percentage:>3}%";
          };

          disk = {
            interval = 1;
            format = "DSK:{percentage_used:>3}%";
          };

          "custom/gpu" = lib.mkIf cfg.modules.gpu.enable {
            interval = 1;
            exec = "cat ${cfg.modules.gpu.usagePath}";
            format = "GPU:{:>3}%";
          };
          "custom/gpu-temp" = lib.mkIf cfg.modules.gpu.enable {
            interval = 1;
            exec = "expr $(cat ${cfg.modules.gpu.temperaturePath}) / 1000";
            format = "{:>3}°C";
          };

          mpris = {
            format = "{player}: {artist} - {album} - {title}";
            format-paused = "{player}: {artist} - {album} - {title}";
          };

          "clock#date" = {
            interval = 1;
            format = "{:%a %d %b %Y}";
          };
          clock = {
            interval = 1;
            format = "{:%T}";
          };

          wireplumber = lib.mkIf cfg.modules.volume.enable {
            format = "VOL:{volume:>3}%";
            format-muted = "VOL: MUT";
          };

          backlight = lib.mkIf cfg.modules.brightness.enable {
            format = "BRT:{percent:>3}%";
          };

          battery = lib.mkIf cfg.modules.battery.enable {
            interval = 1;
            format = "BAT:{capacity:>3}% {power:>4.1f}W";
            format-charging = "BAT:{capacity:>3}%+ {power:.1f}W";
            states = {
              warning = 30;
              critical = 15;
            };
          };
        }
      ];

      style = builtins.readFile ../../config/waybar/style.css;
    };
  };
}
