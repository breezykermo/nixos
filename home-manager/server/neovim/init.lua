local lazypath = vim.fn.stdpath("data") .. "/plugins/lazy.nvim"
if vim.fn.isdirectory(lazypath) == 0 then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"--single-branch",
		"https://github.com/folke/lazy.nvim.git",
		lazypath,
	})
end

vim.opt.runtimepath:prepend(lazypath)

plugins = {
	{ "neovim/nvim-lspconfig" },
	{ "hrsh7th/nvim-cmp" },
	{ "hrsh7th/cmp-nvim-lsp" },
	{ "hrsh7th/cmp-path" },
	{ "hrsh7th/cmp-buffer" },
	{ "ray-x/lsp_signature.nvim" },
	{
		"nvim-tree-sitter/nvim-treesitter",
	},
	{ "kien/ctrlp.vim" },
	{ "junegunn/fzf.vim" },
	{ "preservim/nerdtree" },
	{ "ryanoasis/vim-devicons" },
	{ "tpope/vim-fugitive" },
	{ "ludovicchabant/vim-gutentags" },
	{ "Yggdroot/indentLine" },
	{ "Raimondi/delimitMate" },
	{ "tomtom/tcomment_vim" },
	{ "ntpeters/vim-better-whitespace" },
	{ "mg979/vim-visual-multi" },

	{ "rust-lang/rust.vim" },
	{ "simrat39/rust-tools.nvim" },
	{ "godlygeek/tabular" },

}

require("lazy").setup(plugins, {
	default = {
		lazy = true,
	}
	colorschemes = { "kanagawa" },
})
