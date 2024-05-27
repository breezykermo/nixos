{ config, lib, pkgs, ... }:

{
	imports = [ 
		./hardware-configuration.nix
	];

	# Allow unfree (Dropbox)
	nixpkgs.config.allowUnfree = true;

	# Use the systemd-boot EFI boot loader.
	boot.loader.systemd-boot.enable = true;
	boot.loader.efi.canTouchEfiVariables = true;

	networking.hostName = "loxnix";
	networking.networkmanager.enable = true;

	# Set your time zone.
	time.timeZone = "Europe/Amsterdam";

	# Configure network proxy if necessary
	# networking.proxy.default = "http://user:password@proxy:port/";
	# networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

	# Select internationalisation properties.
	i18n.defaultLocale = "en_US.UTF-8";

	# Define a user account. Don't forget to set a password with ‘passwd’.
	users.users.alice = {
		isNormalUser = true;
		description = "alice";
		extraGroups = [ "networkmanager" "wheel" "audio" ];
	};

	# Enable the flakes feature; requires `git` in systemPackages
	nix.settings.experimental-features = [ "nix-command" "flakes" ];

	# Default packages
	environment.systemPackages = with pkgs; [
		git
		vim
		wget
		curl
	];

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

	# This value determines the NixOS release from which the default
	# settings for stateful data, like file locations and database versions
	# on your system were taken. It's perfectly fine and recommended to leave
	# this value at the release version of the first install of this system.
	# Before changing this value read the documentation for this option
	# (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
	system.stateVersion = "23.11"; # Did you read the comment?
}
