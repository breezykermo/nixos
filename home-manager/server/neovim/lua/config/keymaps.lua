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

-- GitHub URL for current file
function get_github_url()
  -- Get the file path
  local file_path = vim.fn.expand('%:p')
  if file_path == '' then
    print('No file in buffer')
    return
  end

  -- Get the git root directory
  local git_root = vim.fn.systemlist('git -C ' .. vim.fn.shellescape(vim.fn.expand('%:p:h')) .. ' rev-parse --show-toplevel')[1]
  if vim.v.shell_error ~= 0 then
    print('Not in a git repository')
    return
  end

  -- Get the remote URL
  local remote_url = vim.fn.systemlist('git -C ' .. vim.fn.shellescape(git_root) .. ' remote get-url origin')[1]
  if vim.v.shell_error ~= 0 then
    print('No git remote found')
    return
  end

  -- Get the current branch/bookmark (try jj first, then git)
  local branch = nil

  -- Try jj bookmark first
  local jj_bookmark = vim.fn.systemlist('jj log -r @ --no-graph -T "local_bookmarks.join(\\" \\")" 2>/dev/null')[1]
  if vim.v.shell_error == 0 and jj_bookmark and jj_bookmark ~= '' then
    -- Take the first bookmark if multiple exist
    branch = jj_bookmark:match('%S+')
  end

  -- Fall back to git branch
  if not branch or branch == '' then
    branch = vim.fn.systemlist('git -C ' .. vim.fn.shellescape(git_root) .. ' rev-parse --abbrev-ref HEAD')[1]
    if vim.v.shell_error ~= 0 then
      branch = 'main'
    end
  end

  -- Convert remote URL to GitHub web URL
  local github_url = remote_url
  -- Handle SSH format: git@github.com:user/repo.git
  github_url = github_url:gsub('git@github%.com:', 'https://github.com/')
  -- Handle HTTPS format: https://github.com/user/repo.git
  github_url = github_url:gsub('%.git$', '')

  -- Get relative file path from git root
  local relative_path = file_path:sub(#git_root + 2) -- +2 to skip the trailing slash

  -- Get current line number
  local line_num = vim.fn.line('.')

  -- Construct final URL
  local final_url = github_url .. '/blob/' .. branch .. '/' .. relative_path .. '#L' .. line_num

  -- Copy to clipboard
  vim.fn.setreg('+', final_url)
  print('Copied: ' .. final_url)
end

vim.keymap.set('n', '<leader>gh', get_github_url, { noremap = true, silent = true, desc = 'Copy GitHub URL for current file' })
