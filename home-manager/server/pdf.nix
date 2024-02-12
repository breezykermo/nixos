{pkgs, ...}: {

	home.packages = with pkgs; [
		# tectonic
		# biber-for-tectonic
		texlive.combined.scheme-basic
	];

	programs = {
		# see https://github.com/nix-community/home-manager/blob/master/modules/programs/texlive.nix
		# texlive = {
		# 	enable = true;
		# };
	};
}
