-------------------------------------------------------------------------------
--
-- bonsai-nvim: Treesitter injections for Bonsai web syntax in OCaml
--
-- Provides syntax highlighting for:
--   - {%html.jsx| ... |}  → HTML
--   - {%css| ... |}       → CSS
--   - [%css {| ... |}]    → CSS
--   - [%css stylesheet {| ... |}] → CSS
--
-- Injections are handled declaratively via after/queries/ocaml/injections.scm.
-- This module provides a setup() function for future configurability.
--
-- To publish as a standalone plugin, extract:
--   lua/bonsai-nvim/init.lua
--   after/queries/ocaml/injections.scm
--
-------------------------------------------------------------------------------

local M = {}

function M.setup(opts)
  opts = opts or {}
  -- Future configurability (e.g., custom language mappings)

  -- Highlight %{...} OCaml interpolation patterns in ppx_css blocks.
  -- The CSS injection query strips these with #gsub!, but this matchadd
  -- overlay gives them a distinct highlight so they don't appear as
  -- unhighlighted gaps in the CSS.
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "ocaml",
    callback = function()
      vim.fn.matchadd("PreProc", [[%{[^}]*}]])
    end,
  })
end

return M
