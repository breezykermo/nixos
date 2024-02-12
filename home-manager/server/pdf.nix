{pkgs, ...}: {

	home.packages = with pkgs; [
		# XXX trying to switch to tectonic, but haven't yet worked out the correct way to do citations in Org Mode.
		# tectonic
		# biber-for-tectonic
	];

	programs = {
		# see https://github.com/nix-community/home-manager/blob/master/modules/programs/texlive.nix
		# texlive = {
		# 	enable = true;
		# };
		texlive.enable = true;
		texlive.extraPackages = tpkgs: {
			inherit (tpkgs)
				scheme-small
				latex-bin
				latexmk;
		};
	};
}
