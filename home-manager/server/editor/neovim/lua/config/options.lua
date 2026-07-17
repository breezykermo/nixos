-------------------------------------------------------------------------------
--
-- Options
--
-------------------------------------------------------------------------------

-- Set highlight on search
vim.o.hlsearch = true

-- sweet sweet relative line numbers
vim.opt.relativenumber = true
-- and show the absolute line number for the current line
vim.opt.number = true

-- Enable mouse mode
vim.o.mouse = 'a'

-- Always use spaces, always only 2
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.expandtab = true -- Convert tabs to spaces

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.o.clipboard = 'unnamedplus'

-- Enable break indent
-- vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.wo.signcolumn = 'yes'

-- Decrease update time
vim.o.updatetime = 250
vim.o.timeoutlen = 300

-- folds
vim.wo.foldmethod = "indent"
vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.opt.foldlevel = 20

-- NOTE: You should make sure your terminal supports this
vim.o.termguicolors = true

-- Conceal links
-- NOTE: this seems to be buggy in Orgmode
vim.opt.conceallevel = 2
-- vim.opt.concealcursor = 'nc'
