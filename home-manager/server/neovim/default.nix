{ pkgs, lib, ...}: {
	programs.neovim = {
		enable = true;
		defaultEditor = true;
		viAlias = false;
		vimAlias = true;

		withPython3 = true;
		withNodeJs = true;

		extraPackages = [];
		plugins = [
			vimPlugins.nvim-treesitter.withAllGrammars
		];
		extraConfig = lib.fileContents ./init.vim;
 	};

	home.packages = with pkgs; [
		#-- c/c++
		cmake
		cmake-language-server
		gcc
		llvmPackages.clang-unwrapped
		gdb

		#-- python 
		nodePackages.pyright # python language server
		python311Packages.black # formatter
		
		#-- python 
		rust-analyzer
		cargo
		rustfmt

		#-- nix 
		nil
		rnix-lsp
		statix
		deadnix
		
		#-- golang 
		go
		gotools
		gopls # go language server

		#-- bash 
		nodePackages.bash-language-server
		shellcheck

		#-- misc 
		tree-sitter
	];
}
