{ config, lib, pkgs, userName, ... }:
let
  unstableTarball = fetchTarball https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz;
  inter-typeface = pkgs.callPackage ./fonts/inter.nix { inherit lib; };
in
{
  # nmtui and nmcli
  networking.hostName = "loxnix";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.UTF-8";

  services.xserver.xkb.layout = "us";

  # Enable flakes
  nix.settings.experimental-features = ["nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [
    vim 
    git
    wget
    curl
    # Fonts
    nerd-fonts.fira-code
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    inter-typeface
  ];
  fonts.fontconfig = {
    defaultFonts = {
      serif = [ "Inter Variable" ];
      sansSerif = [ "Inter Variable" ];
      monospace = [ "FiraCode Nerd Font Mono" ];
    };
  };

  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      unstable = import unstableTarball {
        config = config.nixpkgs.config;
      };
    };
  };

  # Necessary for Hyprland, otherwise we won't have any of the drivers
  hardware.graphics.enable = true;

  # XDG enables wayland to communicate with XDG programs.
  # Most critically, it allows browsers to screenshare wayland screens.
  xdg = {
    portal = {
      enable = true;
      config.common.default = "*";
      extraPortals = with pkgs; [
        xdg-desktop-portal-wlr
        xdg-desktop-portal-gtk
      ];
    };
  };


  # Perform garbage collection weekly to maintain low disk usage
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 1w";
  };

  # Optimize storage
  # You can also manually optimize the store via:
  #    nix-store --optimise
  # Refer to the following link for more details:
  # https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf-auto-optimise-store
  nix.settings.auto-optimise-store = true;

  nix.extraOptions = ''
    trusted-users = root ${userName} 
  '';
}

