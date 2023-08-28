{
	pkgs,
	hyprland,
	...
}: {
	imports = [
		# hyprland.nixosModules.default
	];

	environment.pathsToLink = ["/libexec"];
	
	services = {
		gvfs.enable = true; # Mount, trash, and other functionalities
		tumbler.enable = true; # Thumbnail support for images
		xserver = {
			enable = true;
			desktopManager = {
				xterm.enable = false;
			};
			displayManager = {
				defaultSession = "hyprland";
				lightdm.enable = false;
				gdm = {
					enable = true;
					wayland = true;
				};
			};
		}
	};

	programs = {
		hyprland = {
			enable = true;
			xwayland = {
				enable = true;
				hidpi = true;
			};
		};
		# monitor backlight control
		light.enable = true;
		thunar.plugins = with pkgs.xfce; [
			thunar-archive-plugin
			thunar-volman
		];
	};

	environment.systemPackages = with pkgs; [
		waybar # the status bar
		swaybg # the wallpaper
		swayidle # the idle timeout
		swaylock # screen lock
		wlogout # logout menu
		wl-clipboard # copying and pasting
		
		wf-recorder # screen recording
		grim # screenshots
		slurp # selecting a region to screenshot
		
		mako # notification daemon, replacemnt for 'dunst'
		
		alsa-utils
		mpd # for playing system sounds

		xfce.thunar
	];

	# fix https://github.com/ryan4yin/nix-config/issues/10
	security.pam.services.swaylock = {};
}
