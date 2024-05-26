{ pkgs, ... }:
{

	# imports = [
	# 	inputs.hyprland.homeManagerModules.default
	# ];

	home.packages = with pkgs; [
		swaybg
		wdisplays
		way-displays
	];

	wayland.windowManager.hyprland = {
		enable = true;
		extraConfig = builtins.readFile ./hypr.conf;
	};

	# home.file.".config/hypr/hyprpaper.conf".source = ./hyprpaper.conf;
}
 
