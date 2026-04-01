{ pkgs, ... }:
{
  home.packages = with pkgs; [
    proton-vpn
    wireguard-tools  # required for WireGuard protocol support
  ];
}
