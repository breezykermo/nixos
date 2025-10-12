-------------------------------------------------------------------------------
--
-- LSP Configuration
--
-------------------------------------------------------------------------------

local lsp = vim.lsp

-- Typescript
lsp.config('ts_ls', {})
lsp.enable('ts_ls')

-- Python
lsp.config('pylsp', {})
lsp.enable('pylsp')

-- Typst
lsp.config('tinymist', {
  cmd = { 'tinymist' },
  filetypes = { 'typst' },
  root_markers = { '.git' },
  single_file_support = true,
})
lsp.enable('tinymist')

lsp.enable('emmet_language_server')
lsp.config('emmet_language_server', {
  filetypes = { "css", "eruby", "html", "javascript", "javascriptreact", "less", "sass", "scss", "pug", "typescriptreact" },
  -- Read more about this options in the [vscode docs](https://code.visualstudio.com/docs/editor/emmet#_emmet-configuration).
  -- **Note:** only the options listed in the table are supported.
  init_options = {
    ---@type table<string, string>
    includeLanguages = {},
    --- @type string[]
    excludeLanguages = {},
    --- @type string[]
    extensionsPath = {},
    --- @type table<string, any> [Emmet Docs](https://docs.emmet.io/customization/preferences/)
    preferences = {},
    --- @type boolean Defaults to `true`
    showAbbreviationSuggestions = true,
    --- @type "always" | "never" Defaults to `"always"`
    showExpandedAbbreviation = "always",
    --- @type boolean Defaults to `false`
    showSuggestionsAsSnippets = false,
    --- @type table<string, any> [Emmet Docs](https://docs.emmet.io/customization/syntax-profiles/)
    syntaxProfiles = {},
    --- @type table<string, string> [Emmet Docs](https://docs.emmet.io/customization/snippets/#variables)
    variables = {},
  },
})

-- vim.lsp.enable('rust_analyzer')
-- vim.lsp.config('rust_analyzer', ...)
lsp.config('rust_analyzer', {
  capabilities = {
    textDocument = {
      publishDiagnostics = {
        dynamicRegistration = true,
        relatedInformation = true,
      },
    },
  },
  settings = {
    ["rust-analyzer"] = {
      cargo = {
        -- see https://www.reddit.com/r/neovim/comments/18i6qu6/configure_rustanalyzer_feature_configuration/?rdt=33707 for more durable solution
        -- allFeatures = true,
        features = {},
      },
      imports = {
        group = {
          enable = false,
        },
      },
      completion = {
        postfix = {
          enable = false,
        },
      },
      checkOnSave = false,
      diagnostics = {
        enable = true,
        -- enableExperimental = true,
      },
    },
  },
})
lsp.enable('rust_analyzer')

-- Show full compile error message (in a floating window)
vim.api.nvim_set_keymap('n', '<leader>e', ":lua vim.diagnostic.open_float()<CR>", { noremap = true, silent = true })

-- Inlay hints
vim.api.nvim_set_hl(0, "LspInlayHint", { fg = "#677aea" })
if vim.fn.has('nvim-0.10') == 1 then
  vim.lsp.inlay_hint.enable()
end
