-------------------------------------------------------------------------------
--
-- Typst BibTeX Citation Picker
--
-------------------------------------------------------------------------------

local bibtex = require('utils.bibtex')

-- Get bibliography file path from current Typst buffer or use default
local function get_bibliography_path()
  local dropbox_directory = "/home/lox/Dropbox/Lachlan Kermode"
  local default_bib = dropbox_directory .. '/lyt/references/master.bib'

  -- Search for #bibliography("path") in current buffer
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for _, line in ipairs(lines) do
    -- Match #bibliography("path") or #bibliography('path')
    local bib_path = line:match('#bibliography%s*%(%s*"([^"]+)"')
                  or line:match("#bibliography%s*%(%s*'([^']+)'")

    if bib_path then
      -- Expand ~ and make path absolute if needed
      bib_path = bib_path:gsub("^~", os.getenv("HOME"))
      if not bib_path:match("^/") then
        -- Relative path - make it relative to current file
        local current_file = vim.api.nvim_buf_get_name(0)
        local current_dir = vim.fn.fnamemodify(current_file, ':h')
        bib_path = current_dir .. '/' .. bib_path
      end
      return bib_path
    end
  end

  -- Fallback to default
  return default_bib
end

-- Create Typst citation picker
local function create_typst_citation()
  local bib_path = get_bibliography_path()
  local entries = bibtex.parse_bibtex_file(bib_path)

  if #entries == 0 then
    print("No BibTeX entries found in: " .. bib_path)
    return
  end

  -- Insert function for Typst citation format
  local insert_citation = function(key)
    local citation = '@' .. key
    -- Insert at cursor position
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row = cursor[1] - 1
    local col = cursor[2]
    vim.api.nvim_buf_set_text(0, row, col, row, col, {citation})
    -- Move cursor after the inserted citation
    vim.api.nvim_win_set_cursor(0, {row + 1, col + #citation})
  end

  bibtex.create_citation_picker(entries, insert_citation, 'Typst Citations')
end

-- Set up keymaps only for typst files
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'typst',
  callback = function()
    vim.keymap.set({'n', 'i'}, '<leader>ac', create_typst_citation, {
      noremap = true,
      silent = true,
      buffer = true,
      desc = 'Insert Typst citation from BibTeX'
    })
  end
})
