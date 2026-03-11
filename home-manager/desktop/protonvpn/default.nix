{ pkgs, ... }:
{
  home.packages = with pkgs; [
    protonvpn-gui
    wireguard-tools  # required for WireGuard protocol support
  ];
}
