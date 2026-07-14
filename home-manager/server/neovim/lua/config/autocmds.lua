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
