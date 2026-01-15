{ pkgs, lib, theme, ... }:

let
  wallpapers = import ../../../wallpapers { inherit pkgs; };

  # Convert hex colors to Hyprland rgba format
  # Using yellow for active border to match tmux, subtle gray for inactive
  activeBorderColor = theme.helpers.toHyprRgba theme.colors.yellow "ff";
  inactiveBorderColor = theme.helpers.toHyprRgba theme.colors.bg3 "aa";
in
{
	imports = [
		./hyprlock.nix
		./hypridle.nix
	];

	home.packages = with pkgs; [
		swaybg
		wdisplays
		way-displays
		brightnessctl
	];

	# Copy FCL wallpaper to home directory
	home.file.".local/share/wallpapers/fcl-widescreen.png" = {
		source = "${wallpapers.fcl-widescreen}/wallpaper.png";
	};

	wayland.windowManager.hyprland = {
		enable = true;
		xwayland.enable = true;
		systemd.variables = ["-all"];
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
 
