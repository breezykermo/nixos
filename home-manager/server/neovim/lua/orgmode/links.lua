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

  if not text then
    print("No text selected")
    return
  end

  -- Use shared link picker
  link_utils.create_link_picker(function(url)
    -- For orgmode, remove .org extension if present
    url = url:gsub('%.org$', '')

    -- Create the Orgmode link
    local org_link = string.format("[[%s][%s]]", url, text)

    -- Replace the selection with the link
    vim.api.nvim_buf_set_text(0, start_pos[1], start_pos[2], end_pos[1], end_pos[2], {org_link})
  end, 'Orgmode Link')
end

vim.keymap.set('v', '<leader>al', create_org_link, { noremap = true, silent = true, desc = 'Create Orgmode link from selection' })
vim.keymap.set('n', '<leader>al', create_org_link, { noremap = true, silent = true, desc = 'Create Orgmode link from word under cursor' })
