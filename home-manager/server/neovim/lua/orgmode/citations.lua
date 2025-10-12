-------------------------------------------------------------------------------
--
-- BibTeX Citation Picker
--
-------------------------------------------------------------------------------

-- Parse BibTeX fields with proper brace balancing
local function parse_bibtex_fields(entry_content)
  local fields = {}
  local i = 1
  local len = #entry_content

  while i <= len do
    -- Find field name pattern: "fieldname = "
    local field_start, field_end, field_name = entry_content:find("(%w+)%s*=%s*", i)

    if not field_start then
      break
    end

    i = field_end + 1
    if i > len then
      break
    end

    local delimiter = entry_content:sub(i, i)
    local field_value = nil

    if delimiter == "{" then
      -- Handle brace-delimited value with proper nesting
      local brace_depth = 1
      local value_start = i + 1
      i = i + 1

      while i <= len and brace_depth > 0 do
        local char = entry_content:sub(i, i)
        if char == "{" then
          brace_depth = brace_depth + 1
        elseif char == "}" then
          brace_depth = brace_depth - 1
        end
        i = i + 1
      end

      if brace_depth == 0 then
        field_value = entry_content:sub(value_start, i - 2)
      end

    elseif delimiter == '"' then
      -- Handle quote-delimited value
      local value_start = i + 1
      i = i + 1

      while i <= len do
        local char = entry_content:sub(i, i)
        if char == '"' then
          field_value = entry_content:sub(value_start, i - 1)
          i = i + 1
          break
        end
        i = i + 1
      end
    else
      -- Skip this field if delimiter is neither { nor "
      i = i + 1
    end

    if field_value then
      -- Clean up the field value (remove extra whitespace, newlines)
      field_value = field_value:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
      fields[field_name:lower()] = field_value
    end
  end

  return fields
end

-- Parse a BibTeX file and return a table of entries
local function parse_bibtex_file(filepath)
  local file = io.open(filepath, "r")
  if not file then
    print("Could not open bibliography file: " .. filepath)
    return {}
  end

  local content = file:read("*all")
  file:close()

  local entries = {}
  local i = 1
  local len = #content

  -- Iterate through content to find each entry
  while i <= len do
    -- Find the start of an entry: @type{key,
    local entry_start, entry_header_end, entry_type, entry_key =
      content:find("@(%w+)%s*{%s*([^,%s]+)%s*,", i)

    if not entry_start then
      break
    end

    -- Start counting braces from the opening brace of the entry
    local brace_start = content:find("{", entry_start, true)
    if not brace_start then
      break
    end

    -- Count braces to find the matching closing brace
    local brace_depth = 1
    local j = brace_start + 1

    while j <= len and brace_depth > 0 do
      local char = content:sub(j, j)
      if char == "{" then
        brace_depth = brace_depth + 1
      elseif char == "}" then
        brace_depth = brace_depth - 1
      end
      j = j + 1
    end

    if brace_depth == 0 then
      -- Extract the entry content (everything between the comma after key and the closing brace)
      local entry_content = content:sub(entry_header_end + 1, j - 2)

      local entry = {
        type = entry_type:lower(),
        key = entry_key,
        fields = parse_bibtex_fields(entry_content)
      }

      table.insert(entries, entry)
    end

    -- Move to the position after this entry
    i = j
  end

  return entries
end

-- Format a BibTeX entry as a Chicago-style citation (author-date format)
local function format_chicago_citation(entry)
  local author = entry.fields.author or "Unknown Author"
  local year = entry.fields.year or "n.d."
  local title = entry.fields.title or "Untitled"

  -- Simplify author names: take first author and handle "and"
  local first_author = author:match("^([^,]+),") or author:match("^([^%s]+)") or author

  -- Check if there are multiple authors
  local has_multiple = author:find(" and ") ~= nil

  -- Extract last name if in "Last, First" format
  local last_name = first_author:match("^([^,]+)") or first_author

  -- Build citation
  local citation
  if has_multiple then
    citation = last_name .. " et al. " .. year
  else
    citation = last_name .. " " .. year
  end

  -- Truncate title if too long
  if #title > 60 then
    title = title:sub(1, 57) .. "..."
  end

  return citation .. " - " .. title
end

-- Get bibliography file path from current buffer or use default
local function get_bibliography_path()
  local dropbox_directory = "/home/lox/Dropbox/Lachlan Kermode"
  local default_bib = dropbox_directory .. '/lyt/references/master.bib'

  -- Search for #+bibliography: in current buffer
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for _, line in ipairs(lines) do
    local bib_path = line:match("^#%+bibliography:%s*(.+)$")
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

-- Clean BibTeX field values by removing all curly braces
local function clean_bibtex_value(value)
  if not value then return value end

  -- Remove outer braces if they wrap the entire value
  value = value:gsub("^{(.*)}$", "%1")

  -- Remove all protective braces around individual words/acronyms
  -- e.g., {DNA} -> DNA, {Knowing} -> Knowing
  value = value:gsub("{([^}]+)}", "%1")

  return value
end

-- Create Orgmode citation picker with Telescope
local function create_org_citation()
  local bib_path = get_bibliography_path()
  local entries = parse_bibtex_file(bib_path)

  if #entries == 0 then
    print("No BibTeX entries found in: " .. bib_path)
    return
  end

  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  local previewers = require('telescope.previewers')

  -- Create a custom previewer to show all BibTeX fields
  local entry_previewer = previewers.new_buffer_previewer({
    title = "Citation Details",
    define_preview = function(self, entry, status)
      -- Get the full entry data
      local bib_entry = entry.bib_entry

      -- Format all fields for display
      local lines = {
        "Entry ID: " .. bib_entry.key,
        "Type: " .. bib_entry.type,
        "",
      }

      -- List of common fields to display in order
      local field_order = {
        "author", "title", "date", "year", "month",
        "journal", "booktitle", "series",
        "volume", "number", "pages",
        "publisher", "address", "organization", "institution", "school",
        "editor", "chapter", "edition",
        "doi", "url", "isbn", "issn", "eprint",
        "abstract", "keywords", "note"
      }

      -- Add fields in order
      for _, field_name in ipairs(field_order) do
        local value = bib_entry.fields[field_name]
        if value and value ~= "" then
          -- Clean and capitalize field name for display
          local cleaned_value = clean_bibtex_value(value)
          local display_name = field_name:sub(1,1):upper() .. field_name:sub(2)
          table.insert(lines, display_name .. ": " .. cleaned_value)
        end
      end

      -- Add any remaining fields not in the standard order
      for field_name, value in pairs(bib_entry.fields) do
        local is_standard = false
        for _, std_field in ipairs(field_order) do
          if field_name == std_field then
            is_standard = true
            break
          end
        end

        if not is_standard and value and value ~= "" then
          local cleaned_value = clean_bibtex_value(value)
          local display_name = field_name:sub(1,1):upper() .. field_name:sub(2)
          table.insert(lines, display_name .. ": " .. cleaned_value)
        end
      end

      -- Write to preview buffer
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)

      -- Enable text wrapping in the preview window
      vim.api.nvim_buf_call(self.state.bufnr, function()
        vim.wo.wrap = true
        vim.wo.linebreak = true  -- Wrap at word boundaries
      end)
    end
  })

  -- Create telescope entries with search terms
  local telescope_entries = {}
  for _, entry in ipairs(entries) do
    -- Create searchable string with all relevant fields
    local search_string = entry.key .. " "
      .. (entry.fields.author or "") .. " "
      .. (entry.fields.title or "") .. " "
      .. (entry.fields.year or "") .. " "
      .. (entry.fields.journal or "") .. " "
      .. (entry.fields.booktitle or "")

    table.insert(telescope_entries, {
      value = entry.key,
      display = entry.key,  -- Simple display: just the entry ID
      ordinal = search_string,
      bib_entry = entry,  -- Store full entry for preview
    })
  end

  pickers.new({}, {
    prompt_title = 'BibTeX Citations',
    finder = finders.new_table({
      results = telescope_entries,
      entry_maker = function(entry)
        return entry
      end,
    }),
    sorter = conf.generic_sorter({}),
    previewer = entry_previewer,
    layout_config = {
      horizontal = {
        width = 0.9,         -- Use 90% of screen width
        preview_width = 0.65, -- Preview takes 65% of picker width
      },
    },
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        if selection then
          local citation = string.format("[cite:@%s]", selection.value)
          -- Insert at cursor position
          local cursor = vim.api.nvim_win_get_cursor(0)
          local row = cursor[1] - 1
          local col = cursor[2]
          vim.api.nvim_buf_set_text(0, row, col, row, col, {citation})
          -- Move cursor after the inserted citation
          vim.api.nvim_win_set_cursor(0, {row + 1, col + #citation})
        end
      end)
      return true
    end,
  }):find()
end

vim.keymap.set({'n', 'i'}, '<leader>ac', create_org_citation, {
  noremap = true,
  silent = true,
  desc = 'Insert Orgmode citation from BibTeX'
})
