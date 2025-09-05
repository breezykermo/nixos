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
		xwayland.enable = true;
		extraConfig = builtins.readFile ./hypr.conf;
	};
}
 
