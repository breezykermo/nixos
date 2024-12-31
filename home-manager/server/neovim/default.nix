{ pkgs, lib, ...}:
{
	programs.neovim = {
		enable = true;
		defaultEditor = true;
		viAlias = false;
		vimAlias = true;

		# withPython3 = true;
		withNodeJs = true;

		extraPackages = [];
		extraConfig = ":luafile /home/alice/nixos-config/home-manager/server/neovim/init.lua";
		plugins = [];
 	};

	home.packages = with pkgs; [
		#-- c/c++
		cmake
		cmake-language-server
		gcc
		llvmPackages.clang-unwrapped
		gdb
    ccls

		#-- rust
		rustup

		#--  language servers
    nodejs # needed for copilot
    nodePackages.bash-language-server
    nodePackages.svelte-language-server
    emmet-language-server
    typescript-language-server
    shellcheck

		#-- misc
		tree-sitter

		#-- nix
		nil       # language server
		statix    # lints
		deadnix   # scan for dead code
	];
}
