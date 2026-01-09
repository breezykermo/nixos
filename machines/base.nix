{ config, lib, pkgs, userName, ... }:
{
  imports = [
    ./modules/boot.nix
    ./modules/power-management.nix
    ./modules/audio.nix
    ./modules/security.nix
    ./modules/keyboard-hardware.nix
    ./modules/usb-automount.nix
  ];

  users.users.${userName} = {
    isNormalUser = true;
    description = "${userName}";
    extraGroups = lib.mkDefault [ "networkmanager" "wheel" "docker" "input" ];
  };

  services = {
    # services.printing.enable = true;
    protonmail-bridge.enable = lib.mkDefault true;
    system76-scheduler.settings.cfsProfiles.enable = lib.mkDefault true;
  };

  programs.virt-manager.enable = lib.mkDefault false;
}
