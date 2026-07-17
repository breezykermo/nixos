-------------------------------------------------------------------------------
--
-- Autocommands
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

-- email - disable all auto-wrapping for aerc
-- Let email clients handle text wrapping themselves
vim.api.nvim_create_augroup("mail_no_wrap", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = "mail_no_wrap",
  pattern = "mail",
  callback = function()
    vim.opt_local.textwidth = 0
    vim.opt_local.wrapmargin = 0
    vim.opt_local.wrap = false
    vim.opt_local.formatoptions = "qj"  -- Only keep 'q' (gq formatting) and 'j' (remove comment leader)
  end
})

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

-- typst filetype detection
vim.api.nvim_create_autocmd({'BufRead', 'BufNewFile'}, {
  pattern = '*.typ',
  callback = function()
    vim.bo.filetype = 'typst'
  end
})

-- Auto-launch jj-diffconflicts whenever a buffer with jj conflict markers loads
-- (default "diff" marker style, e.g. `<<<<<<< conflict 1 of 1`), such as via
-- jj.nvim's <S-k> summary-tooltip -> <CR> workflow, or opening a conflicted
-- file any other way. Restricted to real file buffers so it doesn't fire on
-- scratch/terminal buffers (e.g. jj.nvim's own log/tooltip windows).
vim.api.nvim_create_autocmd('BufReadPost', {
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

-- jj.nvim sets winfixbuf=true on its log/tooltip windows (jj/ui/terminal.lua) but
-- doesn't clear it when it later wipes its own buffer out of that window, so the
-- window is stuck (E1513: Cannot switch buffer) the next time jj.nvim tries to
-- :edit a file into it (e.g. opening a file from the log buffer's summary
-- tooltip). Every jj.nvim-managed buffer carries a `jj_keymaps_set` marker, so
-- clear winfixbuf on any window still showing one right as it's wiped.
vim.api.nvim_create_autocmd('BufWipeout', {
  callback = function(args)
    if not vim.b[args.buf].jj_keymaps_set then
      return
    end
    for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
      pcall(function() vim.wo[win].winfixbuf = false end)
    end
  end,
})

-- <C-d> in the jj.nvim log buffer opens `tuicr` (a code-review TUI) for the commit
-- under the cursor, complementing <S-d> (jj.nvim's native diff). jj.nvim's own keymap
-- config only rebinds built-in actions (its resolver iterates a hardcoded specs table),
-- so a custom handler can't go through setup(); inject a buffer-local map when the log
-- buffer opens. The log buffer is jj.nvim's main terminal buffer -- identified by the
-- `jj_keymaps_set` marker plus terminal.state.buf, which excludes the tooltip/floating
-- buffers. BufEnter fires DURING jj.nvim's buffer creation, before it assigns state.buf
-- and sets jj_keymaps_set, so defer the check to the next tick (run() is synchronous and
-- has finished setting both by then).
vim.api.nvim_create_autocmd({ 'BufWinEnter', 'BufEnter' }, {
  callback = function(args)
    local buf = args.buf
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end
      if not vim.b[buf].jj_keymaps_set or vim.b[buf].tuicr_map_set then
        return
      end
      local ok, term = pcall(require, 'jj.ui.terminal')
      if not ok or term.state.buf ~= buf then
        return
      end
      vim.b[buf].tuicr_map_set = true

      -- `q` from the log quits nvim entirely. jj.nvim's default `q` just bwipeouts
      -- the log buffer, which drops to a stray empty [No Name] when other buffers/tabs
      -- are around (e.g. after Enter opened a file or <C-d> opened tuicr). Treat the
      -- log as home: `:qa!` force-quits regardless of other/unsaved buffers.
      vim.keymap.set('n', 'q', '<cmd>qa!<cr>',
        { buffer = buf, desc = 'Quit nvim from the jj log' })

      -- Global <leader>k is :NERDTreeFind, which errors in the log buffer ("no file
      -- for the current buffer") since it's a fileless terminal buffer. Open the tree
      -- rooted at the cwd (the repo root when launched via `e`) instead.
      vim.keymap.set('n', '<leader>k', '<cmd>NERDTreeCWD<cr>',
        { buffer = buf, desc = 'Open NERDTree at repo root' })

      -- <CR> normally just `jj edit`s the revision under cursor (jj.nvim built-in).
      -- Extend it to also open that commit's first changed file, editable in a new
      -- tab -- the same end state as <S-k><S-k> -> first file -> <CR>. jj.nvim's
      -- keymap config only rebinds built-in actions, so override the buffer-local
      -- <CR> map (same injection as <C-d>).
      vim.keymap.set('n', '<CR>', function()
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
          vim.notify('jj: no revision under cursor', vim.log.levels.WARN)
          return
        end
        -- Resolve the commit's changed files (and repo root) BEFORE editing, while
        -- `rev` still names the target commit.
        local files = vim.fn.systemlist({ 'jj', 'diff', '--name-only', '-r', rev })
        local root = vim.fn.systemlist({ 'jj', 'root' })[1]
        -- Check out the change (synchronous, so the working copy is updated before we
        -- open the file), then refresh the log to reflect the new @.
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
        -- Empty commit (no changed files): fall back to the repo's README.md, else
        -- the first regular file at the repo root.
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
      end, { buffer = buf, desc = 'Edit revision and open its first changed file' })

      vim.keymap.set('n', '<C-d>', function()
      local parser = require('jj.core.parser')
      -- Revision under the cursor. get_revset returns nil on non-revision lines
      -- (graph-only/blank) and on wrapped description lines, so walk back to the
      -- nearest revision line above (mirrors jj.nvim's own get_revset_line).
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
        vim.notify('jj: no revision under cursor', vim.log.levels.WARN)
        return
      end
      -- Run tuicr in its own tab. On exit, close that tab's window and return to the
      -- log tab. Close the WINDOW rather than wiping a captured buffer: jobstart with
      -- term=true can leave the empty tab buffer behind, so wiping only the terminal
      -- buffer would strand that empty buffer in the tab when tuicr quits. stopinsert
      -- restores normal mode so the log cursor responds immediately instead of
      -- lingering in terminal-insert.
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
      end, { buffer = buf, desc = 'Review commit under cursor in tuicr' })
    end)
  end,
})

-- `nvim` with no file argument, launched inside a jj repo, opens straight into the
-- `:J log -r ::` view -- the full history (`::` = all commits), not jj's default
-- truncated revset (the `e`/$EDITOR alias in a project folder). Guarded to fire only on a
-- pristine startup (empty unnamed scratch buffer, no file/dir arg, not piped stdin) so
-- it never hijacks `nvim <file>`, `nvim .`, session restores, or `cmd | nvim -`.
vim.api.nvim_create_autocmd('StdinReadPre', {
  callback = function()
    vim.g._nvim_started_with_stdin = true
  end,
})
vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    -- Decide only from launch intent: no file/dir arg and not piped stdin. Avoid
    -- guarding on the start buffer's buftype/filetype/contents -- another VimEnter
    -- handler (netrw/NERDTree hijack, direnv, barbar) can touch that buffer before
    -- us and trip a strict guard, which is what broke this. An unnamed buffer plus
    -- argc()==0 already rules out `nvim <file>`/`nvim .`; this repo has no session
    -- restore. Defer the work so it runs after the other VimEnter handlers settle.
    if vim.fn.argc() ~= 0 or vim.g._nvim_started_with_stdin then
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
      vim.cmd('J log -r ::')
      -- :J log opens in its own tab (terminal.window.type='tab'), leaving the empty
      -- startup buffer behind in the first tab; wipe it so only the log tab remains.
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
