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
