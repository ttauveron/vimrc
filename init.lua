vim.wo.relativenumber = true

-- highlight trailing whitespace
vim.cmd [[highlight ExtraWhitespace ctermbg=red guibg=red]]
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*",
  command = "match ExtraWhitespace /\\s\\+$/",
})

-- Define the Lua function to format JSON
local function format_json()
  local curpos = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_command "%!jq ."
  vim.api.nvim_win_set_cursor(0, curpos)
end
vim.api.nvim_create_user_command("JsonFmt", format_json, {})

vim.cmd [[silent! autocmd! filetypedetect BufRead,BufNewFile *.tf]]
vim.cmd [[autocmd BufRead,BufNewFile *.hcl set filetype=hcl]]
vim.cmd [[autocmd BufRead,BufNewFile .terraformrc,terraform.rc set filetype=hcl]]
vim.cmd [[autocmd BufRead,BufNewFile *.tf,*.tfvars set filetype=terraform]]
vim.cmd [[autocmd BufRead,BufNewFile *.tfstate,*.tfstate.backup set filetype=json]]

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.o.clipboard = "unnamedplus"

-- Return to last edit position when opening files (You want this!)
vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = "*",
  callback = function()
    local last_pos = vim.api.nvim_buf_get_mark(0, '"')
    if last_pos[1] > 1 and last_pos[1] <= vim.api.nvim_buf_line_count(0) then
      vim.api.nvim_win_set_cursor(0, last_pos)
    end
  end,
})

vim.cmd "let @e = 'df#€ýaxI''f €ýaC''j0df#€ýaxI''f €ýaC''I€kb Iterraform state mv 01j'"
