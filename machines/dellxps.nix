{pkgs, ...}: {
	services = {
		upower = {
			enable = true;
			percentageLow = 30;
			percentageCritical = 15;
			percentageAction = 10;
			criticalPowerAction = "Hibernate";
		};

		physlock = {
			enable = true;
			lockMessage = "<lk@brown.edu>";
			allowAnyUser = true;
			lockOn = {
				suspend = true;	
				hibernate = true;
			};
		};

		# enable sound
		pipewire = {
			enable = true;
			alsa = {
				enable = true;
				support32Bit = true;
			};
			pulse.enable = true;
		};

	};

# necessary for swaylock
# security.pam.services.swaylock = {};

	# necessary for sway
	security.polkit.enable = true;
	hardware.opengl.enable = true;

	# necessary for sound
	security.rtkit.enable = true;
}
