{pkgs, config, ...}: {
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
	powerManagement.powertop.enable = true;
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

	# bluetooth
	hardware.bluetooth.enable = true;

	# https://nixos.wiki/wiki/OBS_Studio, necessary for virtual camera
	boot.kernelModules = [ "v412loopback" ];
	boot.extraModulePackages = with config.boot.kernelPackages; [
		v4l2loopback
	];
	boot.extraModprobeConfig = ''
		options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
	'';
	environment.systemPackages = [ pkgs.v4l-utils ];
	# NB this line is needed for reasons described here: https://discourse.nixos.org/t/normal-users-not-appearing-in-login-manager-lists/4619/4
	environment.shells = with pkgs; [ bashInteractive fish ];
  users.users.alice.shell = pkgs.fish;
}
