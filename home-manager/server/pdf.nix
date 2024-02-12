{pkgs, ...}: {

	home.packages = with pkgs; [
		# tectonic
		# biber-for-tectonic
	];

	programs = {
		# see https://github.com/nix-community/home-manager/blob/master/modules/programs/texlive.nix
		texlive = {
			enable = true;
		};
	};
}
