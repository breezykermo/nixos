{ pkgs, ... }:
{
	home.packages = with pkgs; [
		hyprpaper
	];

	wayland.windowManager.hyprland = {
		enable = true;
		extraConfig = builtins.readFile ./hypr.conf;
	};

	home.file.".config/hypr/hyprpaper.conf".source = ".hyprpaper.conf";

# NB: only available in unstable home manager, as of 2024.05.18
#services.hyprpaper = {
#	enable = true;
#	settings = {
#		ipc = "on";
#		splash = "true";

#		preload = [];

#		wallpaper = [
#			"eDP-1,/home/alice/Dropbox (Brown)/data/wallpapers/bike-wallpaper.jpg"
#		];
#	}; 
#};
}
 
