{pkgs, ...}: {
  gui = {
    enable = true;
  };

  services = {
    # Run `fprintd-enroll -f <finger> <user>` as root to add new fingerprint
    fprintd.enable = true;

    # Add udev rules for flashing planck as regular user
    udev.packages = [pkgs.qmk-udev-rules];

    upower = {
      enable = true;
      percentageLow = 30;
      percentageCritical = 15;
      percentageAction = 10;
      criticalPowerAction = "Hibernate";
    };

    physlock = {
      enable = true;
      lockMessage = "Lachlan Kermode <lk@brown.edu>";
      allowAnyUser = true;
      lockOn.extraTargets = [
        "systemd-suspend-then-hibernate.service"
        "systemd-hybrid-sleep.service"
      ];
    };
  };

  home-manager.users.alice = {
    gui = {
      enable = true;

      monitor = {
        name = "eDP-1";
        height = 1440;
        width = 2560;
        scale = 1.5;
        touch = true;
      };

      waybar.modules = {
        label = "lox@x1carbon";
      };

      laptop = true;
    };

  };
}
