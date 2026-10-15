-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

-- Return to last edit position when opening files (You want this!)
vim.api.nvim_create_autocmd('BufReadPost', {
  pattern = "*",
  callback = function()
    local last_pos = vim.api.nvim_buf_get_mark(0, "\"")
    if last_pos[1] > 1 and last_pos[1] <= vim.api.nvim_buf_line_count(0) then
      vim.api.nvim_win_set_cursor(0, last_pos)
    end
  end,
})
