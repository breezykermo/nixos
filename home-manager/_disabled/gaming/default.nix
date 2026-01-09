{ pkgs, ... }:
{
  home.packages = with pkgs; [
    (wineWowPackages.full.override {
      wineRelease = "staging";
      mingwSupport = true;
    })
    winetricks
  ];

  home.sessionVariables = {
    WINEARCH = "win64";
    WINEPREFIX = "$HOME/wine-battlenet";
  };

  # Steam is installed in dellxps/configuration.nix
}


