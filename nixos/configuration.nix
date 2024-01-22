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

	networking.hostName = "nixos";
	networking.networkmanager.enable = true;

	# Set your time zone.
	time.timeZone = "Europe/Amsterdam";

	# Configure network proxy if necessary
	# networking.proxy.default = "http://user:password@proxy:port/";
	# networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

	# Select internationalisation properties.
	i18n.defaultLocale = "en_US.UTF-8";
	# console = {
	#		font = "Lat2-Terminus16";
	#		keyMap = "us";
	#		useXkbConfig = true; # use xkbOptions in tty.
	# };

	# X11 windowing system.
	# services.xserver.enable = true;
	# services.xserver.layout = "us";
	# services.xserver.xkbOptions = "eurosign:e,caps:escape";
	# services.xserver.libinput.enable = true; # touchpad support

	# CUPS to print documents.
	# services.printing.enable = true;

	# Sound.
	# sound.enable = true;
	# hardware.pulseaudio.enable = true;

	# Define a user account. Don't forget to set a password with ‘passwd’.
	users.users.alice = {
		isNormalUser = true;
		description = "alice";
		extraGroups = [ "networkmanager" "wheel" ];
	};

	nix.settings.experimental-features = [ "nix-command" "flakes" ];

	environment.systemPackages = with pkgs; [
		git
		vim
		wget
		curl
	];

	environment.variables.EDITOR = "vi";

	services.openssh = {
		enable = true;
		settings = {
			X11Forwarding = true;
			PermitRootLogin = "yes";
			PasswordAuthentication = false;
		};
		openFirewall = true;
	};

	# This value determines the NixOS release from which the default
	# settings for stateful data, like file locations and database versions
	# on your system were taken. It's perfectly fine and recommended to leave
	# this value at the release version of the first install of this system.
	# Before changing this value read the documentation for this option
	# (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
	system.stateVersion = "23.11"; # Did you read the comment?
}
