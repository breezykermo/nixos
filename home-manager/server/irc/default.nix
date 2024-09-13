{ config, pkgs, lib, ...}:
{
	home.packages = with pkgs; [
    weechat
  ];
  programs.irssi.enable = true;
}

