{ config, lib, pkgs, userName, ... }:
{
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  users.users.${userName} = {
    isNormalUser = true;
    description = "${userName}";
    extraGroups = lib.mkDefault [ "networkmanager" "wheel" "docker" "input" ];
  };

  # This is necessary to use SSH to get flakes from private GH repos
  programs.ssh.startAgent = lib.mkDefault true;

  services = {

    # printing.enable = true;
    protonmail-bridge.enable = lib.mkDefault true;

    upower = {
      enable = lib.mkDefault true;
      percentageLow = lib.mkDefault 30;
      percentageCritical = lib.mkDefault 15;
      percentageAction = lib.mkDefault 10;
      criticalPowerAction = lib.mkDefault "Hibernate";
    };

    physlock = {
      enable = lib.mkDefault true;
      lockMessage = lib.mkDefault "<lox>";
      allowAnyUser = lib.mkDefault true;
      lockOn = {
        suspend = lib.mkDefault true;
        hibernate = lib.mkDefault true;
      };
    };

    # enable sound
    pipewire = {
      enable = lib.mkDefault true;
      alsa = {
        enable = lib.mkDefault true;
        support32Bit = lib.mkDefault true;
      };
      pulse.enable = lib.mkDefault true;
    };

    system76-scheduler.settings.cfsProfiles.enable = lib.mkDefault true;
    thermald.enable = lib.mkDefault true;
    tlp = {
      enable = lib.mkDefault true;
      settings = {
        CPU_BOOST_ON_AC = lib.mkDefault 1;
        CPU_BOOST_ON_BAT = lib.mkDefault 0;
        CPU_SCALING_GOVERNOR_ON_AC = lib.mkDefault "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = lib.mkDefault "powersave";
      };
    };

    # for flashing keyboards with Keymapp
    udev.extraRules = ''
    # Rules for Oryx web flashing and live training
    KERNEL=="hidraw*", ATTRS{idVendor}=="16c0", MODE="0664", GROUP="plugdev"
    KERNEL=="hidraw*", ATTRS{idVendor}=="3297", MODE="0664", GROUP="plugdev"

    # Wally Flashing rules for the Ergodox EZ
    ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", ENV{ID_MM_DEVICE_IGNORE}="1"
    ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789A]?", ENV{MTP_NO_PROBE}="1"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789ABCD]?", MODE:="0666"
    KERNEL=="ttyACM*", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", MODE:="0666"

    # Keymapp / Wally Flashing rules for the Moonlander and Planck EZ
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", MODE:="0666", SYMLINK+="stm32_dfu"
    # Keymapp Flashing rules for the Voyager
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="3297", MODE:="0666", SYMLINK+="ignition_dfu"

    # remarkable-mouse
    # SUBSYSTEM=="input", ATTR{name}=="reMarkable pen", MODE="0664", GROUP="input"
    # SUBSYSTEM=="input", ATTRS{name}=="reMarkable pen", ENV{LIBINPUT_CALIBRATION_MATRIX}="1 0 0 0 1 0"
    '';
  };

  programs.virt-manager.enable = lib.mkDefault false;

  # usb automounting - disabled by default, Dell enables these
  services.devmon.enable = lib.mkDefault false;
  services.gvfs.enable = lib.mkDefault false;
  services.udisks2.enable = lib.mkDefault false;

  # Limit the number of generations to keep
  boot.loader.systemd-boot.configurationLimit = lib.mkDefault 10;
}
