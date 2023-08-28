{ pkgs, lib, ...}:
let
  pluginGit = ref: repo: pkgs.vimUtils.buildVimPluginFrom2Nix {
    pname = "${lib.strings.sanitizeDerivationName repo}";
    version = ref;
    src = builtins.fetchGit {
      url = "https://github.com/${repo}.git";
      ref = ref;
    };
  };
in
with pkgs;
{
	programs.neovim = {
		enable = true;
		defaultEditor = true;
		viAlias = false;
		vimAlias = true;

		withPython3 = true;
		withNodeJs = true;

		extraPackages = [];
		plugins = [
			vimPlugins.packer-nvim
      vimPlugin.nvim-treesitter
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
