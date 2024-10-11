{ config, lib, pkgs, ... }:
let
# add unstable channel declaratively
	unstableTarball =
		fetchTarball
			https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz;
in
{
	imports = [ 
		./hardware-configuration.nix
	];

	# Allow unfree (Dropbox), and unstable (ollama)
	nixpkgs.config = {
		allowUnfree = true;
    # TODO: remove this! I am not sure which package uses it.
    permittedInsecurePackages = [ "olm-3.2.16" ];
		packageOverrides = pkgs: {
			unstable = import unstableTarball {
				config = config.nixpkgs.config;
			};
		};
	};

	# Use the systemd-boot EFI boot loader.
	boot.loader.systemd-boot.enable = true;
	boot.loader.efi.canTouchEfiVariables = true;

	networking.hostName = "loxnix";
	networking.networkmanager.enable = true;
	# necessary for routing traffic through wireguard
	networking.firewall.checkReversePath = false;

	# Set your time zone.
	time.timeZone = "America/New_York";

	# Configure network proxy if necessary
	# networking.proxy.default = "http://user:password@proxy:port/";
	# networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

	# Select internationalisation properties.
	i18n.defaultLocale = "en_US.UTF-8";

	# Define a user account. Don't forget to set a password with ‘passwd’.
	users.users.alice = {
		isNormalUser = true;
		description = "alice";
		extraGroups = [ "networkmanager" "wheel" "audio" "plugdev" "libvirtd" "docker" ];
	};

	# Enable the flakes feature; requires `git` in systemPackages
	nix.settings.experimental-features = [ "nix-command" "flakes" ];

	# Default packages
	environment = {
		etc."dict.conf".text = "server dict.org";
		systemPackages = with pkgs; [
			git
			vim
			wget
			curl
      dict
      dropbox-cli
      maestral
      maestral-gui
      # development environments
      # devenv
		];
	};

  # Dropbox
  # TODO: work out how to get this in home-manager
  networking.firewall = {
    allowedTCPPorts = [ 17500 ];
    allowedUDPPorts = [ 17500 ];
  };


  # NOTE: this doesn't seem to work any longer
  systemd.user.services.dropbox = {
    description = "Dropbox";
    wantedBy = [ "graphical-session.target" ];
    environment = {
      QT_PLUGIN_PATH = "/run/current-system/sw/" + pkgs.qt5.qtbase.qtPluginPrefix;
      QML2_IMPORT_PATH = "/run/current-system/sw/" + pkgs.qt5.qtbase.qtQmlPrefix;
    };
    serviceConfig = {
      ExecStart = "${lib.getBin pkgs.dropbox}/bin/dropbox";
      ExecReload = "${lib.getBin pkgs.coreutils}/bin/kill -HUP $MAINPID";
      KillMode = "control-group"; # upstream recommends process
      Restart = "on-failure";
      PrivateTmp = true;
      ProtectSystem = "full";
      Nice = 10;
    };
  };
  #
	# NB: not ideal to put it here, but fine for now.
	# programs.steam.enable = true;

	# Enable nix ld for running binaries: see https://github.com/Mic92/nix-ld
  # programs.nix-ld.enable = true;

  # Sets up all the libraries to load
  # programs.nix-ld.libraries = with pkgs; [
  #   stdenv.cc.cc
  #   glib
  #   # ...
  # ];

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

  # for a better setup, see https://github.com/erictossell/nixflakes/blob/main/modules/virt/libvirt.nix 
	virtualisation = {
    # libvirtd.enable = true;
    docker.enable = true;
		# podman = {
		# 	enable = true;
		# 	dockerCompat = true;
		# };
		#
		# oci-containers = {
		# 	backend = "podman";
		#
		# 	containers = {
		# 		# open-webui = import ../home-manager/server/llms/openwebui.nix;
		# 	};
		# };
	};

	# Limit the number of generations to keep
	boot.loader.systemd-boot.configurationLimit = 10;
	# boot.loader.grub.configurationLimit = 10;

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
    trusted-users = root alice
  '';

	# This value determines the NixOS release from which the default
	# settings for stateful data, like file locations and database versions
	# on your system were taken. It's perfectly fine and recommended to leave
	# this value at the release version of the first install of this system.
	# Before changing this value read the documentation for this option
	# (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
	system.stateVersion = "23.11"; # Did you read the comment?
}
