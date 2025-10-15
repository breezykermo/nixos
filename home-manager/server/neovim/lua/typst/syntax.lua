-------------------------------------------------------------------------------
--
-- Typst Syntax Shortcuts
--
-------------------------------------------------------------------------------

local text_utils = require('utils.text')
local link_utils = require('utils.links')

-- Create wrapper functions for Typst syntax
local wrap_emphasis = text_utils.create_wrapper('_', '_')
local wrap_strong = text_utils.create_wrapper('*', '*')
local wrap_code = text_utils.create_wrapper('`', '`')
local wrap_math = text_utils.create_wrapper('$', '$')

-- Math block needs spaces around the content
local wrap_math_block = text_utils.wrap_with_callback(function(text)
  if text == "" then
    -- No text: insert $ $ with cursor between spaces
    return { text = '$  $', cursor_offset = 2 }
  end
  return '$ ' .. text .. ' $'
end)

-- Heading - prompts for level, then prepends appropriate number of =
local wrap_heading = text_utils.wrap_with_callback(function(text)
  local level = tonumber(vim.fn.input('Heading level (1-6): ')) or 1
  level = math.max(1, math.min(6, level))
  local prefix = string.rep('=', level) .. ' '

  if text == "" then
    -- No text: insert heading prefix with cursor at end
    return { text = prefix, cursor_offset = #prefix }
  end
  return prefix .. text
end)

-- Link - creates Typst link with file/URL picker
local function create_typst_link()
  local text, start_pos, end_pos = text_utils.get_text_range()
  local has_text = text ~= nil

  -- If no text, use empty and get cursor position
  if not has_text then
    local cursor = vim.api.nvim_win_get_cursor(0)
    start_pos = {cursor[1] - 1, cursor[2]}
    end_pos = start_pos
    text = ""
  end

  -- Use shared link picker
  link_utils.create_link_picker(function(url)
    -- Create Typst link: #link("url")[label]
    local typst_link = string.format('#link("%s")[%s]', url, text)

    -- Replace the selection (or insert at cursor)
    vim.api.nvim_buf_set_text(0, start_pos[1], start_pos[2], end_pos[1], end_pos[2], {typst_link})

    -- Position cursor between the square brackets (in the label part)
    local link_start = start_pos[2]
    local url_section_length = #('#link("' .. url .. '")')
    local cursor_col = link_start + url_section_length + 1  -- +1 to be inside the brackets
    vim.api.nvim_win_set_cursor(0, {start_pos[1] + 1, cursor_col})
    vim.cmd('startinsert')
  end, 'Typst Link')
end

-- Insert bibliography reference
local function insert_bibliography()
  local bib_text = '#bibliography("./references/master.bib")'
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]
  vim.api.nvim_buf_set_text(0, row, col, row, col, {bib_text})
  -- Move cursor after the inserted text
  vim.api.nvim_win_set_cursor(0, {row + 1, col + #bib_text})
end

-- Set up keymaps only for typst files
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'typst',
  callback = function()
    local opts = { noremap = true, silent = true, buffer = true }

    -- Emphasis/Italic: <leader>ai
    vim.keymap.set({'n', 'v'}, '<leader>ai', wrap_emphasis,
      vim.tbl_extend('force', opts, { desc = 'Typst: _emphasis_' }))

    -- Bold/Strong: <leader>ab
    vim.keymap.set({'n', 'v'}, '<leader>ab', wrap_strong,
      vim.tbl_extend('force', opts, { desc = 'Typst: *strong*' }))

    -- Code: <leader>as
    vim.keymap.set({'n', 'v'}, '<leader>as', wrap_code,
      vim.tbl_extend('force', opts, { desc = 'Typst: `code`' }))

    -- Math inline: <leader>am
    vim.keymap.set({'n', 'v'}, '<leader>am', wrap_math,
      vim.tbl_extend('force', opts, { desc = 'Typst: $math$' }))

    -- Math block: <leader>aM
    vim.keymap.set({'n', 'v'}, '<leader>aM', wrap_math_block,
      vim.tbl_extend('force', opts, { desc = 'Typst: $ math $' }))

    -- Link: <leader>al
    vim.keymap.set({'n', 'v'}, '<leader>al', create_typst_link,
      vim.tbl_extend('force', opts, { desc = 'Typst: #link()[]' }))

    -- Heading: <leader>ah
    vim.keymap.set({'n', 'v'}, '<leader>ah', wrap_heading,
      vim.tbl_extend('force', opts, { desc = 'Typst: = heading' }))

    -- Bibliography: <leader>ar
    vim.keymap.set({'n', 'i'}, '<leader>ar', insert_bibliography,
      vim.tbl_extend('force', opts, { desc = 'Typst: #bibliography()' }))
  end
})
