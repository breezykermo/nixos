{
	config,
	lib,
	pkgs,
	...
}: {
	imports = [
		./core-server.nix
	];

	nixpkgs.config.allowUnfree = lib.mkDefault true;

	environment.shells = with pkgs; [
		bash
		nushell
	];

	users.defaultUserShell = pkgs.nushell;

	environment.systemPackages = with pkgs; [
		(python310.withPackages (ps:
			with ps: [
				ipython
				pandas
				requests
				pyquery
				pyyaml
			]
		))
	];
	
	services.keyd = {
		enable = true;
		settings = {
			main = {
				# overloads the capslock key to function as both escape (when tapped) and control (when held)
				capslock = "overload(control, esc)";
			};
		};
	};	

	networking.firewall.enable = false;

	# more modern alternative to PulseAudio
	services.pipewire = {
		enable = true;
		alsa.enable = true;
		pulse.enable = true;
	}

	security.rtkit.enable = true;

	# causes conflicts with pipewire
	sound.enable = false;
	hardware.pulseaudio.enable = false;

	# bluetooth
	hardware.bluetooth.enable = true;
	services.blueman.enable = true;

	services.power-profiles-daemon = {
		enable = true;
	};
	security.polkit.enable = true;
	services.gnome.gnome-keyring.enable = true;
	security.pam.services.greetd.enableGnomeKeyring = true;

	services = {
		printing.enable = true;
	};

	fonts = {
		enableDefaultFonts = false;
		fontDir.enable = true;
		fonts = with pkgs; [
			material-design-icons
			font-awesome

			# Noto
			noto-fonts
			noto-fonts-cjk
			noto-fonts-emoji
			noto-fonts-extra

			# Adobe
			source-sans
			source-serif

			(nerdfonts.override {
				fonts = [
					"FiraCode"
					"JetBrainsMono"
					"Iosevka"
				];
			})
		];
		
		fontconfig.defaultFonts = {
			serif = ["Noto Serif", "Noto Color Emoji"];
			sansSerif = ["Noto Sans", "Noto Color Emoji"];
			monospace = ["JetBrainsMono Nerd Font" "Noto Color Emoji"];
			emoji = ["Noto Color Emoji"];
		};
	};

	environment.variables = {
		# fix https://github.com/NixOS/nixpkgs/issues/238025
		TZ = "${config.time.timeZone}";
	};
}


