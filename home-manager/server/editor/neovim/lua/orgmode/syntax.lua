-------------------------------------------------------------------------------
--
-- Orgmode Syntax Shortcuts
--
-------------------------------------------------------------------------------

local text_utils = require('utils.text')

-- Create wrapper functions for Orgmode syntax
local wrap_italic = text_utils.create_wrapper('/', '/')
local wrap_bold = text_utils.create_wrapper('*', '*')
local wrap_underline = text_utils.create_wrapper('_', '_')
local wrap_code = text_utils.create_wrapper('~', '~')
local wrap_verbatim = text_utils.create_wrapper('=', '=')
local wrap_strikethrough = text_utils.create_wrapper('+', '+')

-- Set up keymaps only for org files
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'org',
  callback = function()
    local opts = { noremap = true, silent = true, buffer = true }

    -- Italic: <leader>ai
    vim.keymap.set({'n', 'v'}, '<leader>ai', wrap_italic,
      vim.tbl_extend('force', opts, { desc = 'Org: /italic/' }))

    -- Bold: <leader>ab
    vim.keymap.set({'n', 'v'}, '<leader>ab', wrap_bold,
      vim.tbl_extend('force', opts, { desc = 'Org: *bold*' }))

    -- Underline: <leader>au
    vim.keymap.set({'n', 'v'}, '<leader>au', wrap_underline,
      vim.tbl_extend('force', opts, { desc = 'Org: _underline_' }))

    -- Code: <leader>as
    vim.keymap.set({'n', 'v'}, '<leader>as', wrap_code,
      vim.tbl_extend('force', opts, { desc = 'Org: ~code~' }))

    -- Verbatim: <leader>aS
    vim.keymap.set({'n', 'v'}, '<leader>aS', wrap_verbatim,
      vim.tbl_extend('force', opts, { desc = 'Org: =verbatim=' }))

    -- Strikethrough: <leader>ak
    vim.keymap.set({'n', 'v'}, '<leader>ak', wrap_strikethrough,
      vim.tbl_extend('force', opts, { desc = 'Org: +strike+' }))
  end
})
