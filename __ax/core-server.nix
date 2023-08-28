{
	lib,
	pkgs,
	...
}: {
	boot.loader.systemd-boot.configurationLimmit = lib.mkDefault 10;

	nix.gc = {
		automatic = lib.mkDefault true;
		dates = lib.mkDefault "weekly";
		options = lib.mkDefault "--delete-older-than 1w";
	};

	nix.settings = {
		auto-optimise-store = true;
		builders-use-subtitles = true;
		experimental-features = ["nix-command" "flakes"];
	};

	nixpkgs.config.allowUnfree = lib.mkDefault false;

	time.timeZone = "US/Eastern";
	i18n.defaultLocale = "en_US.UTF-8";

	networking.firewall.enable = lib.mkDefault false;

	services.openssh = {
		enable = true;
		settings = {
			X11Forwarding = true;
			PermitRootLogin = "no";
			PasswordAuthentication = false;
		};
		openFirewall = true;
	};

	services = {
		power-profiles-daemon = {
			enable = true;
		};
		upower.enable = true;
	};

	environment.systemPackages = with pkgs; [
		neovim
		wget
		curl
		git
		git-lfs
	];
	
	environment.variables.EDITOR = "nvim";

	virtualisation.docker = {
		enable = true;
		enableOnBoot = true;
	};
}
