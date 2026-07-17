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
