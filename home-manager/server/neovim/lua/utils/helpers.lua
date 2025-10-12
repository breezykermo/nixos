-------------------------------------------------------------------------------
--
-- Helper functions
--
-------------------------------------------------------------------------------

local M = {}

function M.open_file_in_default_app(target)
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

function M.copy_to_clipboard(str)
  vim.fn.setreg('+', str)
end

function M.update_hrefs_from_org_to_html(file_path)
  -- Read the file contents
  local file = io.open(file_path, "r")
  if not file then
    print("File not found!")
    return
  end
  local content = file:read("*all")
  file:close()

  -- Perform the replacement: change .org to .htlm in hrefs
  content = content:gsub('href="([^"]+)%.org"', 'href="%1.html"')

  -- Write the modified content back to the file
  file = io.open(file_path, "w")
  file:write(content)
  file:close()

  print("All .org hrefs changed to .html in " .. file_path)
end

return M
