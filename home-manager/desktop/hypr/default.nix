{ pkgs, ... }:
{
	home.packages = with pkgs; [
		hyprpaper
	];

	wayland.windowManager.hyprland = {
		enable = true;
		extraConfig = builtins.readFile ./hypr.conf;
	};

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
 
