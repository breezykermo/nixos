{ config, pkgs, lib, ...}:
{
  home.packages = with pkgs; [
    devenv
    evince
  ];

  programs = {};
}
