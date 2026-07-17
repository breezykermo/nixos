-- jjx: opinionated extensions and defaults for jj.nvim (NicolasGB/jj.nvim).
--
-- Structured as a standalone module (require('jjx').setup{...}) so it can later be
-- lifted into its own neovim plugin repo. It only reaches into jj.nvim's own modules
-- (jj.core.parser / jj.ui.terminal / jj.cmd.log / jj.utils) -- the thing it extends.
--
-- Dependencies:
--   * HARD: jj.nvim; the `tuicr` binary (for the review keymap).
--   * OPTIONAL (auto-detected, skipped cleanly if absent, never error):
--       - NERDTree                -> <leader>k opens the tree at the repo root
--       - telescope recent-files  -> <space>. opens a recent file in a new tab
--
-- Always-on core: open :J log on no-arg startup, q quits nvim, <CR> also opens a
-- commit's first changed file, <C-d> opens tuicr review, plus the winfixbuf and
-- conflict-marker workarounds.

local M = {}

local defaults = {
  -- Open `:J log` when nvim starts in a jj repo with no file argument.
  startup_log = { enabled = true, revset = '::' },
  -- Feature toggles: 'auto' (detect), true (force on), false (off).
  tuicr = 'auto',
  nerdtree = 'auto',
  picker = 'auto',
  keys = {
    quit = 'q', -- -> :qa!
    review = '<C-d>', -- -> tuicr review in a new tab
    tree = '<leader>k', -- -> :NERDTreeCWD (needs NERDTree)
    picker = '<space>.', -- -> recent-files picker in a new tab (needs telescope)
    -- <CR> is always overridden (jj edit + open first changed file).
  },
}

local config = vim.deepcopy(defaults)

-----------------------------------------------------------------------
-- Feature detection (evaluated lazily, when the log buffer opens, so plugins
-- that load after us are still seen)
-----------------------------------------------------------------------

local function resolve(flag, detect)
  if flag == true then
    return true
  end
  if flag == false then
    return false
  end
  return detect() -- 'auto'
end

local function has_tuicr()
  return vim.fn.executable('tuicr') == 1
end

local function has_nerdtree()
  return vim.fn.exists(':NERDTreeCWD') == 2
end

local function has_picker()
  local ok, telescope = pcall(require, 'telescope')
  if not ok then
    return false
  end
  local ext = (telescope.extensions or {})['recent-files']
  return ext ~= nil and ext.recent_files ~= nil
end

-----------------------------------------------------------------------
-- Shared helpers
-----------------------------------------------------------------------

-- Revision under the cursor. jj.nvim's parser returns nil on non-revision lines
-- (graph-only/blank) and on wrapped description lines, so walk back to the nearest
-- revision line above (mirrors jj.nvim's own get_revset_line).
local function rev_under_cursor(buf)
  local parser = require('jj.core.parser')
  local rev = parser.get_revset(vim.api.nvim_get_current_line())
  if not rev then
    local row = vim.api.nvim_win_get_cursor(0)[1]
    for i = row - 1, 1, -1 do
      local l = vim.api.nvim_buf_get_lines(buf, i - 1, i, false)[1]
      rev = parser.get_revset(l)
      if rev then
        break
      end
    end
  end
  if not rev or rev == '' then
    return nil
  end
  return rev
end

-----------------------------------------------------------------------
-- Keymap handlers
-----------------------------------------------------------------------

-- <CR>: jj edit the revision under cursor, then open its first changed file in a new
-- tab (editable working copy). Empty commit -> README.md, else first visible file.
local function edit_and_open_first_file(buf)
  return function()
    local rev = rev_under_cursor(buf)
    if not rev then
      vim.notify('jj: no revision under cursor', vim.log.levels.WARN)
      return
    end
    -- Resolve changed files + repo root BEFORE editing, while `rev` still names it.
    local files = vim.fn.systemlist({ 'jj', 'diff', '--name-only', '-r', rev })
    local root = vim.fn.systemlist({ 'jj', 'root' })[1]
    vim.fn.system({ 'jj', 'edit', rev })
    if vim.v.shell_error ~= 0 then
      vim.notify('jj edit failed: ' .. rev, vim.log.levels.ERROR)
      return
    end
    pcall(function()
      require('jj.utils').reload_changed_file_buffers()
    end)
    pcall(function()
      require('jj.cmd.log').log({})
    end)
    local target
    for _, f in ipairs(files) do
      if f ~= '' then
        target = root .. '/' .. f
        break
      end
    end
    if not target and root then
      local readme = root .. '/README.md'
      if vim.fn.filereadable(readme) == 1 then
        target = readme
      else
        local entries = vim.fn.readdir(root, function(name)
          local hidden = name:sub(1, 1) == '.'
          local isfile = vim.fn.isdirectory(root .. '/' .. name) == 0
          return (isfile and not hidden) and 1 or 0
        end)
        if entries and entries[1] then
          target = root .. '/' .. entries[1]
        end
      end
    end
    if target then
      vim.schedule(function()
        vim.cmd('tabedit ' .. vim.fn.fnameescape(target))
      end)
    end
  end
end

-- <C-d>: open tuicr for the commit under cursor in its own tab; on exit close that
-- tab's window and return to the log tab. Close the WINDOW (not a captured buffer):
-- jobstart term=true can leave the empty tab buffer behind. stopinsert restores normal
-- mode so the log cursor responds immediately.
local function review_in_tuicr(buf)
  return function()
    local rev = rev_under_cursor(buf)
    if not rev then
      vim.notify('jj: no revision under cursor', vim.log.levels.WARN)
      return
    end
    local log_tab = vim.api.nvim_get_current_tabpage()
    vim.cmd('tabnew')
    local tuicr_win = vim.api.nvim_get_current_win()
    vim.fn.jobstart({ 'tuicr', '-r', rev }, {
      term = true,
      on_exit = function()
        vim.schedule(function()
          if vim.api.nvim_win_is_valid(tuicr_win) then
            pcall(vim.api.nvim_win_close, tuicr_win, true)
          end
          if vim.api.nvim_tabpage_is_valid(log_tab) then
            vim.api.nvim_set_current_tabpage(log_tab)
          end
          vim.cmd('stopinsert')
        end)
      end,
    })
    vim.cmd('startinsert')
  end
end

-- <space>.: telescope recent-files, routed to open the pick in a new tab. The log
-- window is winfixbuf=true (jj.nvim), which blocks the default in-place edit, so the
-- pick would otherwise silently no-op.
local function picker_in_tab()
  local actions = require('telescope.actions')
  require('telescope').extensions['recent-files'].recent_files({
    attach_mappings = function(_, map)
      map({ 'i', 'n' }, '<CR>', actions.select_tab)
      return true
    end,
  })
end

-----------------------------------------------------------------------
-- Per-log-buffer setup
-----------------------------------------------------------------------

local function setup_log_buffer(buf)
  vim.b[buf].jjx_map_set = true
  local k = config.keys

  -- q -> quit nvim entirely. jj.nvim's default q bwipeouts the log, dropping to a
  -- stray empty [No Name] when other buffers/tabs exist. Treat the log as home.
  vim.keymap.set('n', k.quit, '<cmd>qa!<cr>',
    { buffer = buf, desc = 'jjx: quit nvim from the jj log' })

  -- <CR> -> edit + open first changed file (always on).
  vim.keymap.set('n', '<CR>', edit_and_open_first_file(buf),
    { buffer = buf, desc = 'jjx: edit revision and open its first changed file' })

  -- <C-d> -> tuicr review (hard dep; skip cleanly if the binary is missing).
  if resolve(config.tuicr, has_tuicr) then
    vim.keymap.set('n', k.review, review_in_tuicr(buf),
      { buffer = buf, desc = 'jjx: review commit under cursor in tuicr' })
  end

  -- <leader>k -> NERDTree at repo root (optional integration).
  if resolve(config.nerdtree, has_nerdtree) then
    vim.keymap.set('n', k.tree, '<cmd>NERDTreeCWD<cr>',
      { buffer = buf, desc = 'jjx: open NERDTree at repo root' })
  end

  -- <space>. -> recent-files picker in a new tab (optional integration).
  if resolve(config.picker, has_picker) then
    vim.keymap.set('n', k.picker, picker_in_tab,
      { buffer = buf, desc = 'jjx: recent files (open in a new tab)' })
  end
end

-----------------------------------------------------------------------
-- Autocmds
-----------------------------------------------------------------------

local function setup_autocmds()
  local group = vim.api.nvim_create_augroup('jjx', { clear = true })

  -- Auto-launch jj-diffconflicts on buffers with jj conflict markers (default "diff"
  -- style, e.g. `<<<<<<< conflict 1 of 1`). Real file buffers only.
  vim.api.nvim_create_autocmd('BufReadPost', {
    group = group,
    callback = function(args)
      if vim.bo[args.buf].buftype ~= '' then
        return
      end
      for _, line in ipairs(vim.api.nvim_buf_get_lines(args.buf, 0, -1, false)) do
        if line:match('^<+ conflict %d+ of %d+') then
          vim.schedule(function()
            vim.cmd('JJDiffConflicts')
          end)
          return
        end
      end
    end,
  })

  -- jj.nvim sets winfixbuf=true on its log/tooltip windows but doesn't clear it when it
  -- wipes its own buffer out, leaving the window stuck (E1513). Clear it on wipe.
  vim.api.nvim_create_autocmd('BufWipeout', {
    group = group,
    callback = function(args)
      if not vim.b[args.buf].jj_keymaps_set then
        return
      end
      for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
        pcall(function()
          vim.wo[win].winfixbuf = false
        end)
      end
    end,
  })

  -- Inject buffer-local keymaps when the jj.nvim log buffer opens. jj.nvim's own keymap
  -- config only rebinds built-in actions, so custom maps can't go through its setup().
  -- The log buffer is jj.nvim's main terminal buffer (jj_keymaps_set marker +
  -- terminal.state.buf). BufEnter fires DURING buffer creation, before jj.nvim assigns
  -- state.buf / jj_keymaps_set, so defer to the next tick.
  vim.api.nvim_create_autocmd({ 'BufWinEnter', 'BufEnter' }, {
    group = group,
    callback = function(args)
      local buf = args.buf
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(buf) then
          return
        end
        if not vim.b[buf].jj_keymaps_set or vim.b[buf].jjx_map_set then
          return
        end
        local ok, term = pcall(require, 'jj.ui.terminal')
        if not ok or term.state.buf ~= buf then
          return
        end
        setup_log_buffer(buf)
      end)
    end,
  })

  -- No-arg `nvim` in a jj repo opens straight into `:J log`. Decide only from launch
  -- intent (no file/dir arg, not piped stdin, unnamed buffer) -- guarding on the start
  -- buffer's buftype/contents is fragile (other VimEnter handlers touch it first).
  if config.startup_log.enabled then
    vim.api.nvim_create_autocmd('StdinReadPre', {
      group = group,
      callback = function()
        vim.g._jjx_started_with_stdin = true
      end,
    })
    vim.api.nvim_create_autocmd('VimEnter', {
      group = group,
      callback = function()
        if vim.fn.argc() ~= 0 or vim.g._jjx_started_with_stdin then
          return
        end
        local buf = vim.api.nvim_get_current_buf()
        if vim.api.nvim_buf_get_name(buf) ~= '' then
          return
        end
        vim.schedule(function()
          if vim.fn.executable('jj') == 0 then
            return
          end
          vim.fn.system({ 'jj', 'root' })
          if vim.v.shell_error ~= 0 then
            return
          end
          local rev = config.startup_log.revset
          vim.cmd(rev and ('J log -r ' .. rev) or 'J log')
          -- :J log opens in its own tab; wipe the empty startup buffer so only the log
          -- tab remains (and q -> :qa! then exits nvim cleanly).
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(buf)
              and vim.api.nvim_buf_get_name(buf) == ''
              and vim.api.nvim_buf_line_count(buf) == 1
              and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == ''
            then
              pcall(vim.cmd, 'bwipeout ' .. buf)
            end
          end)
        end)
      end,
    })
  end
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

--- @param opts? table Merged over defaults (see `defaults` above).
function M.setup(opts)
  config = vim.tbl_deep_extend('force', vim.deepcopy(defaults), opts or {})
  setup_autocmds()
end

return M
