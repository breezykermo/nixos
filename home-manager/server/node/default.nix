{ pkgs, lib, ...}:
{
	home.packages = with pkgs; [
		nodejs 
	];

	home.file.".npmrc" = {
		source = ./npmrc;
	};
}
