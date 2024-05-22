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
	# improve battery life 
	# https://github.com/TechsupportOnHold/Batterylife/blob/main/laptop.nix
	services.system76-scheduler.settings.cfsProfiles.enable = true;
	services.thermald.enable = true;
	powerManager.powertop.enable = true;
	services.power-profiles-daemon.enable = false;
	services.tlp = {
		enable = true;
		settings = {
			CPU_BOOST_ON_AC = 1;
			CPU_BOOST_ON_BAT = 0;
			CPU_SCALING_GOVERNOR_ON_AC = "performance";
			CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
		};
	};

	# necessary for sway
	security.polkit.enable = true;
	hardware.opengl.enable = true;

	# necessary for sound
	security.rtkit.enable = true;
}
