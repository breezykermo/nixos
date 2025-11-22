{ pkgs, lib, ... }:

let
  theme = import ../../../themes/default.nix { inherit lib; };

  # Convert hex colors to Hyprland rgba format
  activeBorderColor = theme.helpers.toHyprRgba theme.activeBorder "dd";
  inactiveBorderColor = theme.helpers.toHyprRgba theme.inactiveBorder "aa";
in
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
		extraConfig = ''
			${builtins.readFile ./hypr.conf}

			# Theme-specific overrides
			general {
				col.active_border = ${activeBorderColor}
				col.inactive_border = ${inactiveBorderColor}
			}
		'';
	};
}
 
