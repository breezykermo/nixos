{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.custom.homework {
    home.packages = with pkgs; [
      blender
    ];
  };
}
