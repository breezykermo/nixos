{ pkgs, lib, userName, machineVars, theme, ...}:
{
	programs.neovim = {
		enable = true;
		defaultEditor = true;
		viAlias = false;
		vimAlias = true;

		withPython3 = false;
		withRuby = false;
		withNodeJs = true;

		extraPackages = [];
		extraConfig = ''
			:lua vim.g.dropbox_path = "${machineVars.dropboxPath}"
			:lua vim.g.theme_name = "${theme.name}"
			:lua vim.g.theme_variant = "${theme.variant}"
			:luafile /etc/nixos/home-manager/server/neovim/init.lua
		'';
		plugins = with pkgs.vimPlugins; [
			catppuccin-nvim
			rose-pine
		];
    # extraLuaPackages = ["luarocks"];
 	};

	xdg.configFile."nvim/after/queries/ocaml/injections.scm".source =
		./after/queries/ocaml/injections.scm;

	# OCaml REPL (utop) init: auto-load Core/Base and the ppx_jane rewriters.
	# Requires `core` and `ppx_jane` in the active opam switch.
	home.file.".ocamlinit".text = ''
		#require "core.top";;
		#require "ppx_jane";;
		open Base;;
	'';

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
    bash-language-server
    svelte-language-server
    emmet-language-server
    typescript-language-server
    shellcheck
    tinymist # Typst
    (python312Packages.python-lsp-server.overrideAttrs (_: { doInstallCheck = false; }))

		#-- misc
		tree-sitter

		#-- nix
		nil       # language server
		statix    # lints
		deadnix   # scan for dead code

		#-- ocaml (toolchain managed via opam; state lives in ~/.opam)
		opam
		gnumake     # building opam packages
		m4          # conf-m4, used by several opam builds
		pkg-config  # detect system libs during opam builds
		gmp         # zarith and friends
		libev       # lwt/async backend used by utop
	];
}
