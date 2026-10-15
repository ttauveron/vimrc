function OpenSelectedLinks()
  -- Get the current visual selection
  local _, start_row, start_col, _ = unpack(vim.fn.getpos("'<"))
  local _, end_row, end_col, _ = unpack(vim.fn.getpos("'>"))

  -- Ensure correct ordering of start and end in case of backward selection
  if start_row > end_row or (start_row == end_row and start_col > end_col) then
    start_row, end_row = end_row, start_row
    start_col, end_col = end_col, start_col
  end

  -- Capture the lines of the visual selection
  local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)

  -- Adjust the first and last line to respect the start_col and end_col
  lines[1] = string.sub(lines[1], start_col)
  if #lines > 1 then
    lines[#lines] = string.sub(lines[#lines], 1, end_col)
  else
    lines[1] = string.sub(lines[1], 1, end_col - start_col + 1)
  end

  -- Iterate over each line and open it as a URL
  for _, url in ipairs(lines) do
    if url ~= "" then
      -- Use 'xdg-open' for Linux, 'open' for macOS. Adjust the command as needed.
      vim.fn.system({ 'open', url })
    end
  end
end

-- Binding the function to a key combination in visual mode, e.g., \o
vim.api.nvim_set_keymap('v', '\\o', ':lua OpenSelectedLinks()<CR>', { noremap = true, silent = true })
