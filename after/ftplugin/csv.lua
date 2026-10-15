local bufnr = vim.api.nvim_get_current_buf()
local name = vim.api.nvim_buf_get_name(bufnr):lower()

-- If it’s actually a .csv file, switch back to comma and re-init.
if name:sub(-4) == '.csv' then
  vim.b.csv_delim = ','
else
  vim.b.csv_delim = '\t'   -- .tsv
end
vim.cmd('silent! CSVInit') -- apply delimiter, highlights, vartabs

-- Nice viewing defaults (no file edits)
vim.opt_local.wrap = false
vim.opt_local.list = false
vim.b.ibl_enabled = false
vim.b.better_whitespace_enabled = 0

-- Zebra striping / headers (tweak to taste)
vim.cmd('hi link CSVColumnOdd  Identifier')
vim.cmd('hi link CSVColumnEven Normal')
vim.cmd('hi link CSVColumnHeaderOdd  Title')
vim.cmd('hi link CSVColumnHeaderEven Title')

-- Handy buffer-local mappings
local map = function(lhs, rhs, desc)
  vim.keymap.set('n', lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
end
map('<leader>ch', '<Cmd>HiColumn<CR>', 'CSV: toggle current-column highlight')
map('<leader>cc', '<Cmd>WhatColumn<CR>', 'CSV: show current column number')

-- Optional: read-only aligned preview using `column` (does not touch file)
vim.api.nvim_buf_create_user_command(bufnr, 'TSVPreview', function()
  local fname = vim.api.nvim_buf_get_name(bufnr)
  vim.cmd('vert new')
  vim.cmd('setlocal buftype=nofile bufhidden=wipe noswapfile')
  vim.cmd("0read !column -t -s '\\t' " .. vim.fn.fnameescape(fname))
  vim.cmd('1delete _')
end, {})
