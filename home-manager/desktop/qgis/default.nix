{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.custom.homework {
    # Latest QGIS release (pkgs.qgis, currently 4.x); pkgs.qgis-ltr is the older
    # long-term-support line. homework-only, like the other heavy GUI apps here.
    home.packages = with pkgs; [
      qgis
    ];
  };
}
