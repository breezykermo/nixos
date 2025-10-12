-------------------------------------------------------------------------------
--
-- Typst Syntax Shortcuts
--
-------------------------------------------------------------------------------

local text_utils = require('utils.text')

-- Create wrapper functions for Typst syntax
local wrap_emphasis = text_utils.create_wrapper('_', '_')
local wrap_strong = text_utils.create_wrapper('*', '*')
local wrap_code = text_utils.create_wrapper('`', '`')
local wrap_math = text_utils.create_wrapper('$', '$')

-- Math block needs spaces around the content
local wrap_math_block = text_utils.wrap_with_callback(function(text)
  return '$ ' .. text .. ' $'
end)

-- Heading - prompts for level, then prepends appropriate number of =
local wrap_heading = text_utils.wrap_with_callback(function(text)
  local level = tonumber(vim.fn.input('Heading level (1-6): ')) or 1
  level = math.max(1, math.min(6, level))
  return string.rep('=', level) .. ' ' .. text
end)

-- Link - wraps text and prompts for URL
local wrap_link = text_utils.wrap_with_callback(function(text)
  local url = vim.fn.input('URL: ')
  if url == "" then return nil end  -- Cancel if empty
  return string.format('#link("%s")[%s]', url, text)
end)

-- Set up keymaps (using <leader>a prefix as specified)
local opts = { noremap = true, silent = true }

-- Emphasis/Italic: <leader>ai
vim.keymap.set({'n', 'v'}, '<leader>ai', wrap_emphasis,
  vim.tbl_extend('force', opts, { desc = 'Typst: _emphasis_' }))

-- Bold/Strong: <leader>ab
vim.keymap.set({'n', 'v'}, '<leader>ab', wrap_strong,
  vim.tbl_extend('force', opts, { desc = 'Typst: *strong*' }))

-- Code: <leader>ac
vim.keymap.set({'n', 'v'}, '<leader>ac', wrap_code,
  vim.tbl_extend('force', opts, { desc = 'Typst: `code`' }))

-- Math inline: <leader>am
vim.keymap.set({'n', 'v'}, '<leader>am', wrap_math,
  vim.tbl_extend('force', opts, { desc = 'Typst: $math$' }))

-- Math block: <leader>aM
vim.keymap.set({'n', 'v'}, '<leader>aM', wrap_math_block,
  vim.tbl_extend('force', opts, { desc = 'Typst: $ math $' }))

-- Link: <leader>al
vim.keymap.set({'n', 'v'}, '<leader>al', wrap_link,
  vim.tbl_extend('force', opts, { desc = 'Typst: #link()[]' }))

-- Heading: <leader>ah
vim.keymap.set({'n', 'v'}, '<leader>ah', wrap_heading,
  vim.tbl_extend('force', opts, { desc = 'Typst: = heading' }))
