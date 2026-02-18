{ pkgs, machineVars, ... }:

{
  services.hypridle = {
    enable = machineVars.hostname != "dellxps";
    package = pkgs.hypridle;

    settings = {
      general = {
        # Lock before sleep (lid close triggers sleep via systemd)
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };

      listener = [
        # Dim screen after 2.5 minutes
        {
          timeout = 150;
          on-timeout = "brightnessctl -s set 10";
          on-resume = "brightnessctl -r";
        }
        # Turn off display after 5 minutes
        {
          timeout = 300;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        # Lock after 10 minutes
        {
          timeout = 600;
          on-timeout = "loginctl lock-session";
        }
        # Suspend after 15 minutes
        {
          timeout = 900;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
