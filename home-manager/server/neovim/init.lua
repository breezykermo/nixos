-------------------------------------------------------------------------------
--
-- Neovim Configuration Entry Point
--
-------------------------------------------------------------------------------

-- NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = ','
vim.g.maplocalleader = ','

-- Add the lua directory to the runtime path so require() can find our modules
local config_path = vim.fn.stdpath('config')
package.path = package.path .. ';/etc/nixos/home-manager/server/neovim/lua/?.lua'
package.path = package.path .. ';/etc/nixos/home-manager/server/neovim/lua/?/init.lua'

-- Load configuration modules
require('config.options')
require('config.autocmds')
require('config.keymaps')

-- Load utilities
require('utils.helpers')

-- Load plugins and LSP
require('plugins')
require('plugins.lsp')

-- Load orgmode extensions
require('orgmode.citations')
require('orgmode.links')
require('orgmode.syntax')

-- Load typst extensions
require('typst.syntax')
require('typst.citations')
