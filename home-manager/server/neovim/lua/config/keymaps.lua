-------------------------------------------------------------------------------
--
-- Keymaps
--
-------------------------------------------------------------------------------

-- General opts for remaps
local opts = { noremap = true, silent = true }
local map = vim.keymap.set

-- Leader space to remove highlight
vim.api.nvim_set_keymap('n', '<leader><space>', ':nohlsearch<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('', '<space>', ':echo "remove search highlight"<CR>', { noremap = true, silent = true })

-- Keymaps for better default experience
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- NERDTree
map('n', '<leader>k', ':NERDTreeFind<cr>', opts)
-- map('n', '<leader>m', ':NERDTreeToggle<cr>', opts)

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

-- Rename a variable using LSP
vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, {})

-- Find all references to symbol under cursor using LSP
vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, {})

-- Proper vertical splitting (unclear why this doesn't work)
vim.keymap.set("n", "<C-w>c", vim.cmd.split)

-- Git blame
vim.api.nvim_set_keymap("n", "<leader>Gb", ":BlameToggle window<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>gb", ":BlameToggle virtual<CR>", { noremap = true, silent = true })

-- Word count shortcut
vim.api.nvim_set_keymap('v', '<leader>wc', ":'<,'>w !wc -w<CR>", { noremap = true, silent = true })
