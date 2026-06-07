-------------------------------------------------------------------------------
--
-- bonsai-nvim: CSS syntax highlighting for Bonsai ppx_css in OCaml
--
-- WHY THIS EXISTS:
--   Tree-sitter injection queries capture @injection.content by byte ranges
--   into the source buffer — the injected parser always sees the raw text.
--   #gsub! only sets metadata.text, which is ignored for injection.content
--   (only used for injection.language). So we cannot strip %{...} OCaml
--   interpolations before the CSS parser sees them, and the CSS parser
--   chokes on %{ producing cascading ERROR nodes.
--
-- HOW THIS WORKS:
--   1. Find CSS content nodes via OCaml tree-sitter queries
--   2. Strip %{...} with same-length space replacement (preserves positions)
--   3. Parse sanitized CSS with vim.treesitter.get_string_parser
--   4. Run the CSS highlights query against the sanitized tree
--   5. Apply highlights via extmarks mapped back to buffer positions
--
-- To publish as a standalone plugin, extract:
--   lua/bonsai-nvim/init.lua
--   after/queries/ocaml/injections.scm (HTML only)
--
-------------------------------------------------------------------------------

local M = {}

local ns = vim.api.nvim_create_namespace("bonsai_css")

--- Replace %{...} interpolations with same-length spaces to preserve positions
---@param text string CSS text potentially containing %{...} interpolations
---@return string sanitized text with interpolations replaced by spaces
local function sanitize(text)
  return text:gsub("%%{[^}]*}", function(m)
    return (" "):rep(#m)
  end)
end

--- Map (row, col) from string-parser space to buffer position
--- Row 0 has an offset of scol; subsequent rows start at col 0
---@param srow integer start row of the CSS node in the buffer
---@param scol integer start col of the CSS node in the buffer
---@param row integer row from string parser
---@param col integer col from string parser
---@return integer buf_row, integer buf_col
local function to_buf(srow, scol, row, col)
  if row == 0 then
    return srow, scol + col
  end
  return srow + row, col
end

--- Parse sanitized CSS and apply highlights via extmarks
---@param bufnr integer buffer number
---@param node TSNode quoted_string_content node containing CSS
local function highlight_block(bufnr, node)
  local text = vim.treesitter.get_node_text(node, bufnr) or ""
  if text == "" then
    return
  end

  local srow, scol = node:start()
  local clean = sanitize(text)

  -- Parse sanitized CSS with tree-sitter
  local ok, parser = pcall(vim.treesitter.get_string_parser, clean, "css")
  if not ok or not parser then
    return
  end

  local tree = parser:parse()[1]
  if not tree then
    return
  end

  -- Load the standard CSS highlights query (provided by nvim-treesitter)
  local hl_query = vim.treesitter.query.get("css", "highlights")
  if not hl_query then
    return
  end

  -- Apply highlights from the CSS highlights query matches
  for id, n, _ in hl_query:iter_captures(tree:root(), clean) do
    local name = hl_query.captures[id]
    if name then
      local sr, sc = n:start()
      local er, ec = n:end_()
      local br1, bc1 = to_buf(srow, scol, sr, sc)
      local br2, bc2 = to_buf(srow, scol, er, ec)

      -- Guard against invalid ranges
      if br1 >= 0 and br2 >= 0 and not (br1 == br2 and bc1 >= bc2) then
        vim.api.nvim_buf_set_extmark(bufnr, ns, br1, bc1, {
          end_row = br2,
          end_col = bc2,
          hl_group = "@" .. name,
          priority = 110, -- above default tree-sitter priority (100)
        })
      end
    end
  end
end

--- Find and highlight all CSS blocks in the buffer
---@param bufnr integer
local function highlight_buffer(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "ocaml")
  if not ok or not parser then
    return
  end

  local tree = parser:parse()[1]
  if not tree then
    return
  end

  -- Query for all three CSS forms:
  --   [%css {| ... |}]
  --   [%css stylesheet {| ... |}]
  --   {%css| ... |}
  local query_ok, q = pcall(vim.treesitter.query.parse, "ocaml", [[
    (extension
      (attribute_id) @_n
      (#eq? @_n "css")
      (attribute_payload
        (expression_item
          (quoted_string
            (quoted_string_content) @css))))

    (extension
      (attribute_id) @_n2
      (#eq? @_n2 "css")
      (attribute_payload
        (expression_item
          (application_expression
            (quoted_string
              (quoted_string_content) @css)))))

    (quoted_extension
      (attribute_id) @_n3
      (#eq? @_n3 "css")
      (quoted_string_content) @css)
  ]])

  if not query_ok or not q then
    return
  end

  for _, match, _ in q:iter_matches(tree:root(), bufnr) do
    for id, nodes in pairs(match) do
      if q.captures[id] == "css" then
        for _, node in ipairs(nodes) do
          highlight_block(bufnr, node)
        end
      end
    end
  end
end

--- Set up Bonsai CSS highlighting for OCaml files
---@param opts table|nil optional configuration
function M.setup(opts)
  opts = opts or {}

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "ocaml",
    callback = function(ev)
      local bufnr = ev.buf

      -- Schedule initial highlight to let tree-sitter parse first
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(bufnr) then
          highlight_buffer(bufnr)
        end
      end)

      -- Re-highlight on content changes
      local group = vim.api.nvim_create_augroup("bonsai_css_" .. bufnr, { clear = true })
      vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave", "BufWritePost" }, {
        buffer = bufnr,
        group = group,
        callback = function()
          highlight_buffer(bufnr)
        end,
      })

      -- Clean up when buffer is unloaded
      vim.api.nvim_create_autocmd("BufUnload", {
        buffer = bufnr,
        group = group,
        callback = function()
          pcall(vim.api.nvim_del_augroup_by_name, "bonsai_css_" .. bufnr)
        end,
      })
    end,
  })
end

return M
