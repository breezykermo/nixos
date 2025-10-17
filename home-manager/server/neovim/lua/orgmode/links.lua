-------------------------------------------------------------------------------
--
-- Orgmode Link Creator
--
-------------------------------------------------------------------------------

local text_utils = require('utils.text')
local link_utils = require('utils.links')

-- Create Orgmode link from visual selection or current word
local function create_org_link()
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
    -- For orgmode, remove .org extension if present
    url = url:gsub('%.org$', '')

    -- Create the Orgmode link
    local org_link = string.format("[[%s][%s]]", url, text)

    -- Replace the selection (or insert at cursor)
    vim.api.nvim_buf_set_text(0, start_pos[1], start_pos[2], end_pos[1], end_pos[2], {org_link})

    -- If there was no text, position cursor inside the second set of brackets and enter insert mode
    if not has_text then
      local link_start = start_pos[2]
      local url_section_length = #('[[' .. url .. '][')
      local cursor_col = link_start + url_section_length
      vim.api.nvim_win_set_cursor(0, {start_pos[1] + 1, cursor_col})
      vim.cmd('startinsert')
    end
  end, 'Orgmode Link')
end

-- Wrap URL under cursor or selection in Orgmode brackets
local function wrap_url_in_brackets()
  text_utils.wrap_text('[[', ']]')
end

-- Set up keymaps only for org files
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'org',
  callback = function()
    vim.keymap.set('v', '<leader>al', create_org_link, { noremap = true, silent = true, buffer = true, desc = 'Create Orgmode link from selection' })
    vim.keymap.set('n', '<leader>al', create_org_link, { noremap = true, silent = true, buffer = true, desc = 'Create Orgmode link from word under cursor' })
    vim.keymap.set('v', '<leader>lf', wrap_url_in_brackets, { noremap = true, silent = true, buffer = true, desc = 'Wrap selection in Orgmode brackets' })
    vim.keymap.set('n', '<leader>lf', wrap_url_in_brackets, { noremap = true, silent = true, buffer = true, desc = 'Wrap URL under cursor in Orgmode brackets' })
  end
})
