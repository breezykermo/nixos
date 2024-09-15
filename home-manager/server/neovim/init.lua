--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = ','
vim.g.maplocalleader = ','

-------------------------------------------------------------------------------
--
-- autocommands
--
-------------------------------------------------------------------------------
-- highlight yanked text
vim.api.nvim_create_autocmd(
	'TextYankPost',
	{
		pattern = '*',
		command = 'silent! lua vim.highlight.on_yank({ timeout = 500 })'
	}
)
-- jump to last edit position on opening file
vim.api.nvim_create_autocmd(
	'BufReadPost',
	{
		pattern = '*',
		callback = function(ev)
			if vim.fn.line("'\"") > 1 and vim.fn.line("'\"") <= vim.fn.line("$") then
				-- except for in git commit messages
				-- https://stackoverflow.com/questions/31449496/vim-ignore-specifc-file-in-autocommand
				if not vim.fn.expand('%:p'):find('.git', 1, true) then
					vim.cmd('exe "normal! g\'\\""')
				end
			end
		end
	}
)

-------------------------------------------------------------------------------
--
-- Options 
--
-------------------------------------------------------------------------------
-- General opts for remaps
local opts = { noremap = true, silent = true }
local map = vim.keymap.set

-- Set highlight on search
vim.o.hlsearch = true

-- Leader space to remove highlight 
vim.api.nvim_set_keymap('n', '<leader><space>', ':nohlsearch<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('', '<space>', ':echo "remove search highlight"<CR>', { noremap = true, silent = true })

-- sweet sweet relative line numbers
vim.opt.relativenumber = true
-- and show the absolute line number for the current line
vim.opt.number = true

-- Enable mouse mode
vim.o.mouse = 'a'

-- Always use spaces, always only 2 
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.expandtab = true -- Convert tabs to spaces

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.o.clipboard = 'unnamedplus'

-- Enable break indent
-- vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.wo.signcolumn = 'yes'

-- Decrease update time
vim.o.updatetime = 250
vim.o.timeoutlen = 300

-- folds
vim.opt.foldmethod = "indent"
vim.opt.foldlevel = 20 


-- Set completeopt to have a better completion experience
-- vim.o.completeopt = 'menuone,noselect'

-- NOTE: You should make sure your terminal supports this
vim.o.termguicolors = true

-- [[ Basic Keymaps ]]

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
-- vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
-- vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- NERDTree
map('n', '<leader>k', ':NERDTreeFind<cr>', opts)
map('n', '<leader>m', ':NERDTreeToggle<cr>', opts)

-- Tabs, see https://github.com/romgrk/barbar.nvim
map('n', '<C-z>', '<Cmd>BufferPrevious<CR>', opts)
map('n', '<C-x>', '<Cmd>BufferNext<CR>', opts)

-- delete inactive buffers 
vim.cmd [[command! -nargs=0 Ball lua delete_inactive_buffers()]]
function delete_inactive_buffers()
  local current_buffer = vim.api.nvim_get_current_buf()
  local buffers = vim.api.nvim_list_bufs()

  for _, buf in ipairs(buffers) do
    if buf ~= current_buffer and not vim.bo[buf].modified then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
end
vim.keymap.set('n', '<leader>b', ':Ball<CR>')

-------------------------------------------------------------------------------
--
-- Helper functions 
--
-------------------------------------------------------------------------------
local function open_file_in_default_app(target)
  local cmd
  if vim.fn.has("win32") == 1 then
    -- Windows
    cmd = string.format('start "" "%s"', target)
  elseif vim.fn.has("macunix") == 1 then
    -- macOS
    cmd = string.format('open "%s"', target)
  else
    -- Linux and other Unix-like systems
    cmd = string.format('xdg-open "%s"', target)
  end

  local result = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    print("Error opening file: " .. result)
  else
    print("File opened successfully")
  end
end

local function copy_to_clipboard(str)
  vim.fn.setreg('+', str)
end

-------------------------------------------------------------------------------
--
-- Packages 
--
-------------------------------------------------------------------------------

-- Install package manager
--    https://github.com/folke/lazy.nvim
--    `:help lazy.nvim.txt` for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system {
		'git',
		'clone',
		'--filter=blob:none',
		'https://github.com/folke/lazy.nvim.git',
		'--branch=stable', -- latest stable release
		lazypath,
	}
end
vim.opt.rtp:prepend(lazypath)

-- Conceal links
-- NOTE: this seems to be buggy in Orgmode
vim.opt.conceallevel = 2
-- vim.opt.concealcursor = 'nc'

-- Hack to surround links with double square brackets 
vim.keymap.set('n', '<leader>lf', function()
  local keys = vim.api.nvim_replace_termcodes("diW", true, false, true)
  vim.api.nvim_feedkeys(keys, 'n', false)
  local keys_two = vim.api.nvim_replace_termcodes("i[[<Esc>", true, false, true)
  vim.api.nvim_feedkeys(keys_two, 'n', false)
  local keys_three = vim.api.nvim_replace_termcodes("p", true, false, true)
  vim.api.nvim_feedkeys(keys_three, 'n', false)
  local keys_four = vim.api.nvim_replace_termcodes("a]]<Esc>", true, false, true)
  vim.api.nvim_feedkeys(keys_four, 'n', false)
end)

-- Proper vertical splitting (unclear why this doesn't work)
vim.keymap.set("n", "<C-w>c", vim.cmd.split)

-- override colorscheme for org agenda
vim.api.nvim_create_autocmd('ColorScheme', {
  pattern = '*',
  callback = function()
    -- Define own colors
    vim.api.nvim_set_hl(0, '@org.agenda.scheduled', { fg = '#cecece' })
    vim.api.nvim_set_hl(0, '@org.agenda.deadline', { fg = '#adfc1b' })
    vim.api.nvim_set_hl(0, '@org.keyword.done', { fg = '#ffffff' })
  end
})

require('lazy').setup({
	-- Automatically manage Vim.session (for tmux restore)
  -- TODO: not yet working on NixOS
	'tpope/vim-obsession',
 
  -- Allow 'dot' to repeat custom keybindings in Orgmode
  'tpope/vim-repeat',

	-- Highlight matching parens so easier to see
  'luochen1990/rainbow',

	-- Navigation straight out of Neovim into Tmux
	'christoomey/vim-tmux-navigator',

	-- Multi-cursor
	'mg979/vim-visual-multi',

	-- Nerd tree
	'preservim/nerdtree',

  -- Rainbow delimiters
  'hiphish/rainbow-delimiters.nvim',

  -- Org mode
  {
    'nvim-orgmode/orgmode',
    event = 'VeryLazy',
    ft = { 'org' },
    config = function()
      -- Setup orgmode
      -- https://github.com/nvim-orgmode/orgmode/blob/master/DOCS.md
      require('orgmode').setup({
        org_agenda_files = {
          '~/Brown Dropbox/Lachlan Kermode/lyt/org/**/*',
          '~/Brown Dropbox/Lachlan Kermode/lyt/course.*',
          '~/Brown Dropbox/Lachlan Kermode/lyt/research.*',
          '~/Brown Dropbox/Lachlan Kermode/lyt/teach.*',
          '~/Brown Dropbox/Lachlan Kermode/lyt/index.*',
          '~/Brown Dropbox/Lachlan Kermode/lyt/wiki.*',
          '~/Brown Dropbox/Lachlan Kermode/lyt/freelance.*',
        },
        org_deadline_warning_days = 4,
        org_default_notes_file = '~/Brown Dropbox/Lachlan Kermode/lyt/org/inbox.org',
        win_split_mode = 'vertical',
        -- 'SOON' items are TODOs that should be filtered out of main list, i.e. only upon returning to the file
        -- 'PROJ' is deprecated. 
        -- All tags are considered non-active so that the filter for TODOs is clean.
        org_todo_keywords = {'TODO', '|', 'SOON', 'PROJ', 'STRT', 'IDEA', 'KILL', 'DONE'},
        org_todo_keyword_faces = {
          -- purple = ':foreground #a660f7',
          IDEA = ':foreground #23b4ed',
          STRT = ':foreground #adfc1b :weight bold',
          SOON = ':foreground #009333',
          TODO = ':foreground #009333 :underline on', -- overrides builtin color for `TODO` keyword
        },
        org_todo_repeat_to_state = 'TODO',
        org_startup_indented = false,
        org_adapt_indentation = false,
        org_blank_before_new_entry = { heading = false, plain_list_item = false },
        org_hide_leading_stars = true,
        -- select content in TODO item = vah 
        mappings = {
          global = {
            org_agenda = '<leader>aa',
            org_capture = '<leader>ac',
          },
          org = {
            org_export = '<leader>ae',
            org_insert_link = '<leader>al',
            org_open_at_point = '<leader>ao',
            org_edit_special = '<leader>a\'',
            org_add_note = '<leader>an',
            org_meta_return = false,
            org_insert_heading_respect_content = '<leader><CR>',
            org_deadline = '<leader>ad',
            org_schedule = '<leader>as',
            org_priority = '<leader>ap',
          },
          agenda = {
            org_agenda_deadline = '<leader>ad',
            org_agenda_schedule = '<leader>as',
          },
          capture = {
            org_capture_kill = '<leader>k',
          },
        },
        org_custom_exports = {
          -- 'e' is the shortcut prompt 
          e = {
            label = 'Export to PDF (with citations)',
            action = function(exporter)
              local current_file = vim.api.nvim_buf_get_name(0)
              local target = vim.fn.fnamemodify(current_file, ':p:r')..'.pdf'
              local current_dir = vim.fn.getcwd()
              local reference_path = current_dir .. "/references/a.csl"
              -- pandoc -s --bibliography="./references/master.bib" --citeproc --csl ./references/ieee.csl --pdf-engine tectonic -o $FNAME.pdf $FNAME.org
              local command = {
                'pandoc', 
                '-s',
                '--bibliography',
                current_dir .. '/references/master.bib',
                '--citeproc',
                '--csl',
                -- current_dir .. '/references/chicago-fullnote-bibliography.csl',
                current_dir .. '/references/syllabus.csl',
                -- current_dir .. '/references/chicago-syllabus.csl',
                '--pdf-engine',
                'tectonic',
                '-o', 
                target,
                current_file 
              }
              local on_success = function(output)
                vim.api.nvim_echo({{ table.concat(output, '\n') }}, true, {})
                copy_to_clipboard(target)
              end
              local on_error = function(err)
                vim.api.nvim_echo({{ table.concat(err, '\n'), 'ErrorMsg' }}, true, {})
                vim.api.nvim_echo(target, true, {})
              end
              return exporter(command , target, on_success, on_error)
            end
          }

        },
        ui = {
          folds = {
            colored = true
          }
        }
      })
    end,
  },
  -- Autopair
  {
    'windwp/nvim-autopairs',
    event = "InsertEnter",
    config = true
    -- use opts = {} for passing setup options
    -- this is equalent to setup({}) function
  },

	-- tabs at the top
	{'romgrk/barbar.nvim',
    dependencies = {
      'nvim-tree/nvim-web-devicons', -- OPTIONAL: for file icons
    },
    init = function() vim.g.barbar_auto_setup = false end,
    opts = {},
    version = '^1.0.0', -- optional: only update when a new 1.x version is released
  },

	-- "gc" to comment visual regions/lines
	{ 'numToStr/Comment.nvim', opts = {} },

  -- main color scheme
  {
	  "wincent/base16-nvim",
	  lazy = false, -- load at start
	  priority = 1000, -- load first
	  config = function()
		  vim.cmd([[colorscheme base16-gruvbox-dark-hard]])

		  -- Set the background transparen:
		  vim.cmd [[
        highlight Normal guibg=NONE ctermbg=NONE
        highlight NonText guibg=NONE ctermbg=NONE
		  ]]

		  -- Make comments more prominent -- they are important.
		  local bools = vim.api.nvim_get_hl(0, { name = 'Boolean' })
		  vim.api.nvim_set_hl(0, 'Comment', bools)

      -- Inlay hints
      vim.api.nvim_set_hl(0, "LspInlayHint", { fg = "#677aea" })
      vim.lsp.inlay_hint.enable()
	  end
  },

  -- Highlight todo, notes, etc in comments
  { 'folke/todo-comments.nvim', 
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' }, 
    opts = { signs = false }
  },

 	-- Inline function signatures
	-- {
	-- 	"ray-x/lsp_signature.nvim",
	-- 	event = "VeryLazy",
	-- 	opts = {},
	-- 	config = function(_, opts)
	-- 		-- Get signatures (and _only_ signatures) when in argument lists.
	-- 		require "lsp_signature".setup({
	-- 			doc_lines = 0,
	-- 			handler_opts = {
	-- 				border = "none"
	-- 			},
	-- 		})
	-- 	end
	-- },

  -- Status line
  {
	  'nvim-lualine/lualine.nvim',
	  dependencies = { 'nvim-tree/nvim-web-devicons' },
	  opts = {
		  options = {
			  icons_enabled = false,
			  theme = 'onedark',
			  component_separators = '|',
			  section_separators = '',
		  },
	  },
  },

	-- Quick navigation
	{
		'ggandor/leap.nvim',
		config = function()
			-- require('leap').create_default_mappings()
		end
	},
  { -- Fuzzy Finder (files, lsp, etc)
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { -- If encountering errors, see telescope-fzf-native README for installation instructions
        'nvim-telescope/telescope-fzf-native.nvim',

        -- `build` is used to run some command when the plugin is installed/updated.
        -- This is only run then, not every time Neovim starts up.
        build = 'make',

        -- `cond` is a condition used to determine whether this plugin should be
        -- installed and loaded.
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      -- Useful for getting pretty icons, but requires a Nerd Font.
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
      'mollerhoj/telescope-recent-files.nvim',
    },
    config = function()
      -- Two important keymaps to use while in Telescope are:
      --  - Insert mode: <c-/>
      --  - Normal mode: ?
      --
      -- This opens a window that shows you all of the keymaps for the current
      -- Telescope picker. This is really useful to discover what Telescope can
      -- do as well as how to actually do it!

      -- [[ Configure Telescope ]]
      -- See `:help telescope` and `:help telescope.setup()`
      require('telescope').setup {
        -- You can put your default mappings / updates / etc. in here
        --  All the info you're looking for is in `:help telescope.setup()`
        pickers = {
          -- order with most recent first
          buffers = {
            ignore_current_buffer = true,
            sort_lastused = true,
          },
          oldfiles = {
            only_cwd = true,
          },
        },

        extensions = {},
      }

      -- Enable Telescope extensions if they are installed
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'recent-files')
      -- pcall(require('telescope').load_extension, 'ui-select')
      -- pcall(require('telescope').load_extension, 'frecency')

      -- Main search, all in directory with recent files first
      -- See: https://github.com/mollerhoj/telescope-recent-files.nvi
      vim.keymap.set('n', '<space>.', function()
        require('telescope').extensions['recent-files'].recent_files({})
      end, { noremap = true, silent = true })

      -- See `:help telescope.builtin`
      local builtin = require 'telescope.builtin'

      vim.keymap.set('n', '<leader>sg', builtin.git_files, { desc = '[S]earch [G]it Files' })
      vim.keymap.set('n', '<leader>sb', builtin.buffers, { desc = '[S]earch existing [B]uffers' })
      vim.keymap.set('n', '<leader>sr', builtin.oldfiles, { desc = '[S]earch [R]ecent Files ("." for repeat)' })
      vim.keymap.set('n', '<leader>sa', builtin.live_grep, { desc = '[S]earch [A]ll Files by Grep' })

      vim.keymap.set('n', '<leader>st', builtin.treesitter, { desc = '[S]earch by [T]reesitter' })
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })

      -- Slightly advanced example of overriding default behavior and theme
      vim.keymap.set('n', '<leader>si', function()
        -- You can pass additional configuration to Telescope to change the theme, layout, etc.
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end, { desc = '[/] Fuzzily search in current buffer' })
    end,
  },

  { -- LSP Plugins
    -- Main LSP Configuration
    'neovim/nvim-lspconfig',
    dependencies = {
      -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
      { 'j-hui/fidget.nvim', opts = {} },

      -- Allows extra capabilities provided by nvim-cmp
      'hrsh7th/cmp-nvim-lsp',
    },
    config = function()
      require('lspconfig').svelte.setup({})
      require('lspconfig').clangd.setup({})
      
    end,
  },

  { -- Autoformat
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>F',
        function()
          require('conform').format { async = true, lsp_fallback = true }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        -- Disable "format_on_save lsp_fallback" for languages that don't
        -- have a well standardized coding style. You can add additional
        -- languages here or re-enable it for the disabled ones.
        local disable_filetypes = { c = true, cpp = true }
        return {
          timeout_ms = 500,
          lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
        }
      end,
      formatters_by_ft = {
        -- Conform can also run multiple formatters sequentially
        -- python = { "isort", "black" },
        --
        -- You can use 'stop_after_first' to run the first available formatter from the list
        -- javascript = { "prettierd", "prettier", stop_after_first = true },
      },
    },
  },

  { -- Autocompletion
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    dependencies = {
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-path',
    },
    config = function()
      -- See `:help cmp`
      local cmp = require 'cmp'

      cmp.setup {
        snippet = {
          -- REQUIRED by nvim-cmp. get rid of it once we can
          -- expand = function(args)
          --   vim.fn["vsnip#anonymous"](args.body)
          -- end,
        },
        completion = { completeopt = 'menu,menuone,noinsert' },

        -- For an understanding of why these mappings were
        -- chosen, you will need to read `:help ins-completion`
        --
        -- No, but seriously. Please read `:help ins-completion`, it is really good!
        mapping = cmp.mapping.preset.insert {
          -- Select the [n]ext item
          ['<C-n>'] = cmp.mapping.select_next_item(),
          -- Select the [p]revious item
          ['<C-p>'] = cmp.mapping.select_prev_item(),

          -- Scroll the documentation window [b]ack / [f]orward
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),

          -- Accept ([y]es) the completion.
          --  This will auto-import if your LSP supports it.
          --  This will expand snippets if the LSP sent a snippet.
          ['<C-y>'] = cmp.mapping.confirm { select = true },

          -- If you prefer more traditional completion keymaps,
          -- you can uncomment the following lines
          ['<CR>'] = cmp.mapping.confirm { select = true },
          ['<Tab>'] = cmp.mapping.select_next_item(),
          ['<S-Tab>'] = cmp.mapping.select_prev_item(),

          -- Manually trigger a completion from nvim-cmp.
          --  Generally you don't need this, because nvim-cmp will display
          --  completions whenever it has completion options available.
          ['<C-Space>'] = cmp.mapping.complete {},

        },
        sources = {
          { name = 'orgmode' },
          { name = 'nvim_lsp' },
          { name = 'path' },
        },
        experimental = {
          ghost_text = true,
        },
      }
    end,
  },

  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    opts = {
      ensure_installed = { 'bash', 'c', 'diff', 'rust', 'html', 'markdown', 'markdown_inline', 'query', },
      -- Autoinstall languages that are not installed
      auto_install = true,
      highlight = {
        enable = true,
        -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
        --  If you are experiencing weird indenting issues, add the language to
        --  the list of additional_vim_regex_highlighting and disabled languages for indent.
        additional_vim_regex_highlighting = { 'ruby' },
      },
      indent = { enable = true, disable = { 'ruby' } },
    },
    config = function(_, opts)
      -- [[ Configure Treesitter ]] See `:help nvim-treesitter`

      ---@diagnostic disable-next-line: missing-fields
      require('nvim-treesitter.configs').setup(opts)
    end,
  },

  -- TODO: work out how to get this into LSP config
  -- Rust defaults
  {
	  'mrcjkb/rustaceanvim',
	  version = '^4', -- Recommended
	  ft = { 'rust' }
  },
}, {})



