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

-- email
-- see https://brianbuccola.com/line-breaks-in-mutt-and-vim/
vim.api.nvim_create_augroup("mail_trailing_whitespace", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = "mail_trailing_whitespace",
  pattern = "mail",
  callback = function()
    vim.opt_local.formatoptions:append('w')
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
