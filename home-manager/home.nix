{ ... }:


{
	imports = [
		./server
		./desktop
	];

	gui = {
		enable = true;

		monitor = {
			name = "eDP-1";
			height = 1440;
			width = 2560;
			scale = 1.5;
			touch = true;
		};

		waybar.modules = {
			label = "simon@x1carbon";
			cpu.temperaturePath = "/sys/class/hwmon/hwmon4/temp1_input";
		};

		laptop = true;
	};

	home = {
		username = "alice";
		homeDirectory = "/home/alice";
	};

	home.stateVersion = "23.05";

	programs.home-manager.enable = true;
}
