{pkgs, ...}: {
  services = {
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

  # enable sound
  hardware.pulseaudio.enable = true;
  sound.enable = true;
  nixpkgs.config.pulseaudio = true;

  # necessary for swaylock, see https://github.com/nix-community/home-manager/blob/master/modules/programs/swaylock.nix 
  security.pam.services.swaylock = {};
  security.polkit.enable = true;
  hardware.opengl.enable = true;
}
