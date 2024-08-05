{ pkgs, lib, ...}:
{
	home.packages = with pkgs; [
		nodejs 
		nodePackages."svelte-language-server"
	];

	home.file.".npmrc" = {
		source = ./npmrc;
	};
}
