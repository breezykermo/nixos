{ config, lib, pkgs, userName, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  # Dell XPS overrides from machines/base.nix defaults

  # Add additional user groups for Dell
  users.users.${userName} = {
    extraGroups = [ "networkmanager" "wheel" "audio" "plugdev" "libvirtd" "docker" "adbusers" ];
  };

  # Disable protonmail-bridge on Dell
  services.protonmail-bridge.enable = false;

  # Disable lid close suspend - keep laptop running when lid is closed
  services.logind = {
    lidSwitch = "ignore";
    lidSwitchDocked = "ignore";
    lidSwitchExternalPower = "ignore";
  };

  # Enable virt-manager on Dell
  programs.virt-manager.enable = true;

  # Enable USB automounting on Dell
  services.devmon.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
