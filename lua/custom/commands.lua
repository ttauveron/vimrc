-- Define the Lua function to format JSON
local function format_json()
  local curpos = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_command('%!jq .')
  vim.api.nvim_win_set_cursor(0, curpos)
end
vim.api.nvim_create_user_command('JsonFmt', format_json, {})

require('custom.shell')
require('custom.base64')
require('custom.links')
require('custom.legacy')
