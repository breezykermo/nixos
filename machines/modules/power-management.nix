{ lib, ... }:
{
  services.upower = {
    enable = lib.mkDefault true;
    percentageLow = lib.mkDefault 30;
    percentageCritical = lib.mkDefault 15;
    percentageAction = lib.mkDefault 10;
    criticalPowerAction = lib.mkDefault "Hibernate";
  };

  services.tlp = {
    enable = lib.mkDefault true;
    settings = {
      CPU_BOOST_ON_AC = lib.mkDefault 1;
      CPU_BOOST_ON_BAT = lib.mkDefault 0;
      CPU_SCALING_GOVERNOR_ON_AC = lib.mkDefault "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = lib.mkDefault "powersave";
    };
  };

  services.thermald.enable = lib.mkDefault true;
}
