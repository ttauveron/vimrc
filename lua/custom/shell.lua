-- yyPgv:!bash<CR>
local function execute_current_line_and_insert_output()
  -- Get the current line number and the line's text
  local line_num = vim.api.nvim_win_get_cursor(0)[1]
  local line_to_execute = vim.api.nvim_get_current_line()

  -- Execute the line as a bash command
  local handle = io.popen(line_to_execute, 'r')
  if handle == nil then
    print("Failed to execute command")
    return
  end
  local command_output = handle:read("*a") -- Read the entire output
  handle:close()

  -- Split the command output into lines
  local output_lines = {}
  for s in command_output:gmatch("[^\r\n]+") do
    table.insert(output_lines, s)
  end

  -- Insert the output below the current line
  if #output_lines > 0 then
    vim.api.nvim_buf_set_lines(0, line_num, line_num, false, output_lines)
  end
end
vim.keymap.set('n', '<leader>zz', execute_current_line_and_insert_output,
  { desc = 'Execute current line as bash command and insert output below' })
