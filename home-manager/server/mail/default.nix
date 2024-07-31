{ pkgs, lib, ...}:
{
	home.packages = with pkgs; [
		protonmail-bridge
	];
}
