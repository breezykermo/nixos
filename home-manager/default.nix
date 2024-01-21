{ ... }:

{
	imports = [
		./server
		./desktop
	];

  wayland.windowManager.sway = {
    enable = true;
		config = rec {
			modifier = "Mod4";
			terminal = "alacritty";
			output = {
				"DP-2" = {
					mode = "1920x1200";
				};
			};
		};
  };

	home.username = "alice";
	home.homeDirectory = "/home/alice";
	home.stateVersion = "23.11";
	programs.home-manager.enable = true;
}
