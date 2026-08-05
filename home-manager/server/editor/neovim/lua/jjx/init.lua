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
  startup_log = { enabled = true },
  -- Default revset for EVERY log render inside nvim: the startup buffer and each
  -- refresh jj.nvim performs after a mutating command. It has to be applied at the
  -- module level (see install_log_revset_default) rather than as a `-r` on the
  -- startup command, because jj.cmd.log merges every call against its own defaults,
  -- which carry no `revisions` -- so a startup-only revset would snap back to jj's
  -- `revsets.log` (`::`) the first time you hit <CR>.
  --
  -- `::` (all commits) matches the top-level `revsets.log` set in
  -- home-manager/server/editor/vcs/default.nix, so plain `jj log` and the nvim log
  -- buffer always agree, and every workspace's tip is included (each workspace's `@`
  -- is a visible head, and `::` covers all of them). Caveat inherited from jj itself:
  -- a sibling workspace's uncommitted edits read as `(empty)` until some jj command
  -- runs inside that workspace's own root.
  --
  -- Set to `false` -- not nil -- to defer to jj's own `revsets.log`: setup() merges
  -- with vim.tbl_deep_extend, and a nil field is simply absent from the override
  -- table, so it would silently leave this default standing.
  log_revset = '::',
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

-- True if raw command-line flags already pin a revset, so the default must stand
-- aside. Covers `-r`, `-r<rev>`, `--revisions <rev>` and `--revisions=<rev>`.
local function has_revset_flag(raw_flags)
  for _, f in ipairs(raw_flags or {}) do
    if f:match('^%-r') or f:match('^%-%-revisions') then
      return true
    end
  end
  return false
end

-- Wrap a jj.nvim log entry point so a call that names no revset gets config.log_revset.
local function with_default_revset(orig)
  return function(opts)
    opts = opts or {}
    if config.log_revset and opts.revisions == nil and not has_revset_flag(opts.raw_flags) then
      opts = vim.tbl_extend('force', opts, { revisions = config.log_revset })
    end
    return orig(opts)
  end
end

local log_revset_wrapped = false

-- Install the default revset by wrapping jj.nvim's log entry points. Idempotent, and
-- a no-op when jj.nvim isn't loaded yet -- callers re-invoke it later.
local function install_log_revset_default()
  if log_revset_wrapped or not config.log_revset then
    return
  end
  local ok, log_mod = pcall(require, 'jj.cmd.log')
  if not ok then
    return
  end
  -- Two dispatch surfaces, and wrapping only the obvious one silently leaves half the
  -- refreshes on jj's `revsets.log`: the ~20 call sites inside jj/cmd/log.lua resolve
  -- `M.log` through this table at call time, but jj/cmd/init.lua takes a *snapshot*
  -- (`M.log = log_module.log`) at load, and both the `:J log` dispatcher and its own
  -- ~30 post-command refreshes go through that copy. So wrap both tables.
  log_mod.log = with_default_revset(log_mod.log)
  local ok_cmd, cmd_mod = pcall(require, 'jj.cmd')
  if ok_cmd and cmd_mod.log then
    cmd_mod.log = with_default_revset(cmd_mod.log)
  end
  log_revset_wrapped = true
end

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
--
-- Launch profile: XDG_CONFIG_HOME points at ~/.config/tuicr-nvim, a second tuicr
-- config tree (home-manager/server/editor/vcs/default.nix) that turns the file list
-- on and single-file view (`:f`) on -- the standalone `dj` alias keeps the plain
-- whole-diff layout. tuicr has no config key for the initially focused panel, so
-- `;h` (leader-h -> focus file list) is sent once the job is up.
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
    local job = vim.fn.jobstart({ 'tuicr', '-r', rev }, {
      term = true,
      env = { XDG_CONFIG_HOME = vim.fn.expand('~/.config/tuicr-nvim') },
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
    if job > 0 then
      -- Focus the file tree. Deferred so the keys land after tuicr has entered
      -- raw mode; anything written earlier still sits in the pty buffer, so the
      -- delay only guards against the terminal setup, not against a slow diff.
      vim.defer_fn(function()
        pcall(vim.fn.chansend, job, ';h')
      end, 200)
    end
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
-- Idle auto-refresh
-----------------------------------------------------------------------

-- Refresh the open log buffer WITHOUT jj.nvim's `M.log()`, which wipes and recreates
-- the terminal buffer (terminal.run) and so tears the hsplit down and rebuilds it --
-- the visible flash. Instead reuse the log buffer's still-open nvim_open_term channel:
-- run `jj log` in a pty job (sized to the window so wrapping/colour match), BUFFER its
-- full output, then paint clear+content in ONE chan_send on exit. One atomic redraw --
-- no blank frame, no top-down fill. jj log is fast, so buffering the whole thing is
-- cheap. Falls back to M.log() if the log buffer isn't currently open.
local function refresh_in_place()
  local ok_term, term = pcall(require, 'jj.ui.terminal')
  local ok_log, log = pcall(require, 'jj.cmd.log')
  if not (ok_term and ok_log) or not term.is_log_buffer_open() then
    if ok_log then log.log({}) end
    return
  end
  local buf, chan = term.state.buf, term.state.chan
  if not (buf and chan and vim.api.nvim_buf_is_valid(buf)) then
    log.log({})
    return
  end
  local win = vim.fn.bufwinid(buf)
  if win == -1 then
    return -- log buffer exists but isn't shown; nothing to repaint
  end
  local cursor = vim.api.nvim_win_get_cursor(win)
  local cmd = log.build_log_cmd({ revisions = config.log_revset })
  local chunks = {}
  vim.fn.jobstart(cmd, {
    pty = true,
    width = vim.api.nvim_win_get_width(win),
    height = vim.api.nvim_win_get_height(win),
    env = { TERM = 'xterm-256color', PAGER = 'cat', COLORTERM = 'truecolor', DFT_BACKGROUND = 'light' },
    on_stdout = function(_, data)
      chunks[#chunks + 1] = table.concat(data, '\n')
    end,
    on_exit = function()
      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end
      -- Clear screen + scrollback + home, then the whole new frame, in one write.
      vim.api.nvim_chan_send(chan, '\27[2J\27[3J\27[H' .. table.concat(chunks))
      vim.defer_fn(function()
        if vim.api.nvim_win_is_valid(win) then
          pcall(vim.api.nvim_win_set_cursor, win, cursor)
        end
      end, 20) -- let the terminal finish painting before restoring the cursor
    end,
  })
end

-- After IDLE_DELAY_MS without activity in the log buffer, refresh it every
-- REFRESH_INTERVAL_MS until the user moves again -- keeps concurrent-agent sessions
-- live without a keypress. A programmatic refresh must not count as activity (the
-- repaint can fire CursorMoved), so guard with `refreshing` cleared on a short defer to
-- absorb any async event.
local uv = vim.uv or vim.loop
local IDLE_DELAY_MS = 3000
local REFRESH_INTERVAL_MS = 2000
local idle = { timer = nil, last_activity = 0, refreshing = false }

local function mark_activity()
  if not idle.refreshing then
    idle.last_activity = uv.now()
  end
end

local function stop_idle_timer()
  if idle.timer then
    idle.timer:stop()
    pcall(function() idle.timer:close() end)
    idle.timer = nil
  end
end

local function start_idle_refresh(buf)
  stop_idle_timer()
  idle.last_activity = uv.now()
  idle.timer = uv.new_timer()
  idle.timer:start(REFRESH_INTERVAL_MS, REFRESH_INTERVAL_MS, function()
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(buf) then
        stop_idle_timer()
        return
      end
      if vim.api.nvim_get_current_buf() ~= buf then
        return -- only refresh while the log is focused
      end
      if uv.now() - idle.last_activity < IDLE_DELAY_MS then
        return
      end
      idle.refreshing = true
      pcall(refresh_in_place)
      vim.defer_fn(function() idle.refreshing = false end, 300)
    end)
  end)
end

-----------------------------------------------------------------------
-- Per-log-buffer setup
-----------------------------------------------------------------------

local function setup_log_buffer(buf)
  vim.b[buf].jjx_map_set = true
  local k = config.keys

  -- Idle auto-refresh: reset the clock on any activity, then run the timer.
  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI', 'ModeChanged', 'TextChanged' }, {
    buffer = buf,
    callback = mark_activity,
  })
  start_idle_refresh(buf)

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
          -- Late install, in case jj.nvim hadn't loaded when setup() ran. Note the
          -- revset deliberately never reaches the Ex cmdline as `J log -r <rev>`:
          -- `trunk() | trunk().. | working_copies()` would be split on whitespace and
          -- its `|` read as a command separator. The wrapper injects it below the
          -- cmdline instead, so bare `:J log` is both safe and correct.
          install_log_revset_default()
          vim.cmd('J log')
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
  install_log_revset_default()
  setup_autocmds()
end

return M
