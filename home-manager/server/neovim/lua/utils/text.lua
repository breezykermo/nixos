-------------------------------------------------------------------------------
--
-- Text Selection and Manipulation Utilities
--
-------------------------------------------------------------------------------

local M = {}

-- Get text range from either visual selection or word under cursor
-- Returns: text (string or nil), start_pos {row, col}, end_pos {row, col}
function M.get_text_range()
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
    return nil, nil, nil
  end

  -- Get the selected text
  local selected_lines = vim.api.nvim_buf_get_text(0, start_row, start_col, end_row, end_col, {})

  if not selected_lines or #selected_lines == 0 then
    return nil, nil, nil
  end

  -- Join lines if multiple lines selected
  local selected_text = table.concat(selected_lines, " ")

  return selected_text, {start_row, start_col}, {end_row, end_col}
end

-- Wrap selected text with prefix and suffix
-- If keep_selection is true, maintains visual selection after wrapping
-- If no text is selected, inserts prefix+suffix and positions cursor in between (insert mode)
function M.wrap_text(prefix, suffix, keep_selection)
  local text, start_pos, end_pos = M.get_text_range()

  if not text then
    -- No text selected - insert wrapper and position cursor in the middle
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row = cursor[1] - 1
    local col = cursor[2]
    local wrapper = prefix .. suffix

    vim.api.nvim_buf_set_text(0, row, col, row, col, {wrapper})

    -- Position cursor between prefix and suffix in insert mode
    local cursor_col = col + #prefix
    vim.api.nvim_win_set_cursor(0, {row + 1, cursor_col})
    vim.cmd('startinsert')
    return
  end

  local wrapped = prefix .. text .. suffix

  -- Replace the selection with wrapped text
  vim.api.nvim_buf_set_text(0, start_pos[1], start_pos[2], end_pos[1], end_pos[2], {wrapped})

  -- Optionally restore visual selection
  if keep_selection and vim.fn.mode():match('[vV]') then
    -- Calculate new end position
    local new_end_col = start_pos[2] + #wrapped
    vim.api.nvim_win_set_cursor(0, {start_pos[1] + 1, start_pos[2]})
    vim.cmd('normal! v')
    vim.api.nvim_win_set_cursor(0, {start_pos[1] + 1, new_end_col - 1})
  end
end

-- Create a simple wrapper function for a given prefix/suffix pair
function M.create_wrapper(prefix, suffix)
  return function()
    M.wrap_text(prefix, suffix or prefix)
  end
end

-- Wrap text using a callback function
-- callback_fn receives the selected text (or "" if none) and should return:
--   - wrapped text string to replace the selection
--   - OR a table { text = "...", cursor_offset = N } for custom cursor positioning
--   - nil to cancel the operation
-- If no text is selected and callback returns a string, cursor is positioned at the end in insert mode
function M.wrap_with_callback(callback_fn)
  return function()
    local text, start_pos, end_pos = M.get_text_range()
    local has_text = text ~= nil

    -- If no text, use empty string and get cursor position
    if not has_text then
      local cursor = vim.api.nvim_win_get_cursor(0)
      start_pos = {cursor[1] - 1, cursor[2]}
      end_pos = start_pos
      text = ""
    end

    -- Call the callback to get the wrapped text
    local result = callback_fn(text)

    -- If callback returns nil, operation is cancelled
    if not result then
      if not has_text then
        -- Only print cancellation if there was actual user interaction (e.g., input prompt)
        -- For simple wrappers with no text, we shouldn't reach here
      end
      return
    end

    -- Handle result - can be string or table with cursor_offset
    local wrapped, cursor_offset
    if type(result) == "table" then
      wrapped = result.text
      cursor_offset = result.cursor_offset or #wrapped
    else
      wrapped = result
      cursor_offset = #wrapped
    end

    -- Replace the selection (or insert at cursor) with wrapped text
    vim.api.nvim_buf_set_text(0, start_pos[1], start_pos[2], end_pos[1], end_pos[2], {wrapped})

    -- If no text was selected, position cursor and enter insert mode
    if not has_text then
      local cursor_col = start_pos[2] + cursor_offset
      vim.api.nvim_win_set_cursor(0, {start_pos[1] + 1, cursor_col})
      vim.cmd('startinsert')
    end
  end
end

return M
