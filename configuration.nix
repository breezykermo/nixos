{ config, lib, pkgs, userName, ... }:
let
  unstableTarball = fetchTarball https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz;
  inter-typeface = pkgs.callPackage ./fonts/inter.nix { inherit lib; };
in
{
  # nmtui and nmcli
  networking.hostName = "loxnix";
  networking.networkmanager.enable = true;
  # necessary for routing traffic through wireguard
  networking.firewall.checkReversePath = false;

  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.UTF-8";

  services.xserver.xkb.layout = "us";

  # Enable flakes
  nix.settings.experimental-features = ["nix-command" "flakes" ];

  # NOTE: temporary workaround to solve maestral Python 3.13 error
  nixpkgs.overlays = [
    (self: super: {
      maestral = super.maestral.overrideAttrs (old: {
        # doCheck = false;
        # Optional: Add Python version pinning for extra safety
        python = pkgs.python312;
      });
    })
  ];

  environment.systemPackages = with pkgs; [
    vim 
    git
    wget
    curl
    # Fonts
    corefonts
    nerd-fonts.fira-code
    docker-compose
    maestral
    pcmanfm
    v4l-utils
  ];

  # For scrcpy
  programs.adb.enable = true;

  # for a potentially better setup, see 
  # https://github.com/erictossell/nixflakes/blob/main/modules/virt/libvirt.nix 
  virtualisation = {
    docker.enable = true;
  };

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    inter-typeface
    corefonts
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
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # https://nixos.wiki/wiki/OBS_Studio, necessary for virtual camera
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=2 video_nr=1,2 card_label="OBS Cam, Virt Cam" exclusive_caps=1
  '';
  security.polkit.enable = true;
  # NB this line is needed for reasons described here: https://discourse.nixos.org/t/normal-users-not-appearing-in-login-manager-lists/4619/4shell
  environment.shells = with pkgs; [ bashInteractive ];

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
    mime.defaultApplications = {
      "application/pdf" = [
        "org.pwmt.zathura.desktop"
        "brave-browser.desktop"
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

