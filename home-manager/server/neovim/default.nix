{ pkgs, lib, ...}:
{
	programs.neovim = {
		enable = true;
		defaultEditor = true;
		viAlias = false;
		vimAlias = true;

		# withPython3 = true;
		# withNodeJs = true;

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

		#-- python
		# nodePackages.pyright # python language server
		# python311Packages.black # formatter

		#-- rust
		rustup
		rust-analyzer

		#-- nix
		# nil
		# rnix-lsp
		# statix
		# deadnix

		#-- bash
		nodePackages.bash-language-server
		shellcheck

		#-- misc
		tree-sitter
	];
}
