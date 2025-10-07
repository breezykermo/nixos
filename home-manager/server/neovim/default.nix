{ pkgs, lib, userName, ...}:
{
	programs.neovim = {
		enable = true;
		defaultEditor = true;
		viAlias = false;
		vimAlias = true;

		# withPython3 = true;
		withNodeJs = true;

		extraPackages = [];
		extraConfig = ":luafile /etc/nixos/home-manager/server/neovim/init.lua";
		plugins = [];
    # extraLuaPackages = ["luarocks"];
 	};

	home.packages = with pkgs; [
		#-- c/c++
		cmake
		gcc
		llvmPackages.clang-unwrapped
		gdb

		#-- rust
		rustup
    # NOTE: delegates cargo components such as rust-analyzer to rustup
    # Run `rustup update` to get new versions.
    # Run `rustup component add rust-analyzer` for each branch.

		#--  language servers
    nodejs # needed for copilot
    bun # JS bundler for dev
    nodePackages.bash-language-server
    nodePackages.svelte-language-server
    emmet-language-server
    typescript-language-server
    shellcheck
    tinymist # Typst
    python312Packages.python-lsp-server

		#-- misc
		tree-sitter

		#-- nix
		nil       # language server
		statix    # lints
		deadnix   # scan for dead code
	];
}
