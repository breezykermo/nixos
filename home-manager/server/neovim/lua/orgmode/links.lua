-------------------------------------------------------------------------------
--
-- Orgmode Link Creator
--
-------------------------------------------------------------------------------

-- Create Orgmode link from visual selection or current word
local function create_org_link()
  local mode = vim.fn.mode()
  local start_row, start_col, end_row, end_col

  if mode == 'n' then
    -- Normal mode: get the WORD under cursor
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local line = vim.api.nvim_get_current_line()
    local row = cursor_pos[1] - 1
    local col = cursor_pos[2]

    -- Find the start of the WORD (non-whitespace)
    local word_start = col
    while word_start > 0 and line:sub(word_start, word_start):match('%S') do
      word_start = word_start - 1
    end
    word_start = word_start + 1

    -- Find the end of the WORD (non-whitespace)
    local word_end = col + 1
    while word_end <= #line and line:sub(word_end, word_end):match('%S') do
      word_end = word_end + 1
    end

    -- Set positions
    start_row = row
    start_col = word_start - 1  -- 0-indexed
    end_row = row
    end_col = word_end - 1  -- 0-indexed, exclusive
  else
    -- Visual mode: use current selection
    local start_pos = vim.fn.getpos('v')
    local end_pos = vim.fn.getpos('.')

    -- Convert to 0-indexed for nvim API
    start_row = start_pos[2] - 1
    start_col = start_pos[3] - 1
    end_row = end_pos[2] - 1
    end_col = end_pos[3]

    -- Normalize positions (ensure start is before end)
    if start_row > end_row or (start_row == end_row and start_col > end_col) then
      start_row, end_row = end_row, start_row
      start_col, end_col = end_col, start_col
    end
  end

  -- Ensure we have valid positions
  if start_row == end_row and start_col >= end_col then
    print("No text selected")
    return
  end

  -- Get the selected text
  local selected_lines = vim.api.nvim_buf_get_text(0, start_row, start_col, end_row, end_col, {})

  if not selected_lines or #selected_lines == 0 then
    print("No text selected")
    return
  end

  -- Join lines if multiple lines selected
  local selected_text = table.concat(selected_lines, " ")

  -- Use Telescope to select a file or enter a URL
  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')

  -- Get git root for relative path calculation
  local git_root = vim.fn.systemlist('git rev-parse --show-toplevel')[1]
  local current_file = vim.api.nvim_buf_get_name(0)
  local current_dir = vim.fn.fnamemodify(current_file, ':h')

  pickers.new({}, {
    prompt_title = 'Link URL (select file or type URL)',
    finder = finders.new_oneshot_job({ 'git', 'ls-files' }, {
      cwd = git_root,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()

        -- Get the typed text from prompt BEFORE closing
        local picker = action_state.get_current_picker(prompt_bufnr)
        local prompt_text = picker:_get_prompt()

        actions.close(prompt_bufnr)

        local url
        if selection then
          -- File was selected from git repo - use relative path
          local selected_file = git_root .. '/' .. selection[1]
          -- Calculate relative path from current file's directory to selected file
          local relative_path = vim.fn.fnamemodify(selected_file, ':~:.')
          -- For orgmode, remove .org extension if present and use just the filename
          url = relative_path:gsub('%.org$', '')
        else
          -- No selection, use the typed text from prompt
          url = prompt_text
        end

        if url == "" then
          print("Cancelled")
          return
        end

        -- Create the Orgmode link
        local org_link = string.format("[[%s][%s]]", url, selected_text)

        -- Replace the selection with the link
        vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, {org_link})
      end)
      return true
    end,
  }):find()
end

vim.keymap.set('v', '<leader>al', create_org_link, { noremap = true, silent = true, desc = 'Create Orgmode link from selection' })
vim.keymap.set('n', '<leader>al', create_org_link, { noremap = true, silent = true, desc = 'Create Orgmode link from word under cursor' })
