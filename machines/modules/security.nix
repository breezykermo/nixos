{ lib, ... }:
{
  # Hyprlock screen locker (Wayland-native, replaces physlock)
  programs.hyprlock.enable = lib.mkDefault true;
  security.pam.services.hyprlock = {};

  # SSH agent for git access to private repos
  programs.ssh.startAgent = lib.mkDefault true;
}
