{ lib, ... }:
{
  # USB automounting - disabled by default
  # Machine configs can enable these services as needed
  services.devmon.enable = lib.mkDefault false;
  services.gvfs.enable = lib.mkDefault false;
  services.udisks2.enable = lib.mkDefault false;
}
