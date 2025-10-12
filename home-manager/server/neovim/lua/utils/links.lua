-------------------------------------------------------------------------------
--
-- Link Creation Utilities
--
-------------------------------------------------------------------------------

local M = {}

-- Create a Telescope picker for selecting files or entering URLs
-- callback_fn receives the selected/typed URL
-- title: optional title for the picker
function M.create_link_picker(callback_fn, title)
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
    prompt_title = title or 'Link URL (select file or type URL)',
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

          -- Ensure path starts with ./ for local files
          if not relative_path:match('^%.%.?/') and not relative_path:match('^/') then
            url = './' .. relative_path
          else
            url = relative_path
          end
        else
          -- No selection, use the typed text from prompt
          url = prompt_text
        end

        if url == "" then
          print("Cancelled")
          return
        end

        -- Call the callback with the URL
        callback_fn(url)
      end)
      return true
    end,
  }):find()
end

return M
