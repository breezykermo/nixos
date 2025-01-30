{ config, lib, pkgs, userName, ... }:
  {
  imports = [ 
    ./hardware-configuration.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # necessary for routing traffic through wireguard
  networking.firewall.checkReversePath = false;

  users.users.${userName} = {
    isNormalUser = true;
    description = "${userName}";
    extraGroups = [ "networkmanager" "wheel" "audio" "plugdev" "libvirtd" "docker" "adbusers" ];
  };

  # Dropbox
  # TODO: is this still necessary for Maestral? 
  networking.firewall = {
    allowedTCPPorts = [ 17500 ];
    allowedUDPPorts = [ 17500 ];
  };

  # usb automounting
  services.devmon.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  # Enable nix ld for running binaries: see https://github.com/Mic92/nix-ld
  # programs.nix-ld.enable = true;

  # for flashing keyboards with Keymapp
  services.udev.extraRules = ''
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
  '';

  programs.virt-manager.enable = true;

	services = {
		upower = {
			enable = true;
			percentageLow = 30;
			percentageCritical = 15;
			percentageAction = 10;
			criticalPowerAction = "Hibernate";
		};

		physlock = {
			enable = true;
			lockMessage = "<lox>";
			allowAnyUser = true;
			lockOn = {
				suspend = true;	
				hibernate = true;
			};
		};

		# enable sound
		pipewire = {
			enable = true;
			alsa = {
				enable = true;
				support32Bit = true;
			};
			pulse.enable = true;
		};

	  system76-scheduler.settings.cfsProfiles.enable = true;
    thermald.enable = true;
    tlp = {
      enable = true;
      settings = {
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      };
    };
	};

  # Limit the number of generations to keep
  boot.loader.systemd-boot.configurationLimit = 10;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
