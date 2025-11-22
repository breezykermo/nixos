{ pkgs, lib, ... }:

let
  theme = import ../../../themes/default.nix { inherit lib; };

  # Convert hex colors to Hyprland rgba format
  # Using yellow for active border to match tmux, subtle gray for inactive
  activeBorderColor = theme.helpers.toHyprRgba theme.colors.yellow "ff";
  inactiveBorderColor = theme.helpers.toHyprRgba theme.colors.bg3 "aa";
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
 
