-- Start reading application output at the beginning rather than at the PTY cursor.
local M = {}

function M.top()
  vim.schedule(function()
    -- Do not interrupt a program that is currently reading terminal input.
    if vim.api.nvim_get_mode().mode:sub(1, 1) == 't' then return end
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buffer = vim.api.nvim_win_get_buf(win)
      if vim.bo[buffer].filetype == 'dapui_console' then
        vim.api.nvim_win_call(win, function()
          vim.cmd('normal! ggzt')
          -- DAP UI uses this event to stop following the end of the output.
          vim.api.nvim_exec_autocmds('CursorMoved', { buffer = buffer, modeline = false })
        end)
      end
    end
  end)
end

function M.setup()
  local group = vim.api.nvim_create_augroup('PythonConsoleView', { clear = true })
  vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter', 'TermOpen' }, {
    group = group,
    callback = function(event)
      if vim.bo[event.buf].filetype == 'dapui_console' then M.top() end
    end,
  })
  local dap = require('dap')
  for _, event in ipairs({ 'event_stopped', 'event_exited', 'event_terminated' }) do
    dap.listeners.after[event]['python-console-top'] = M.top
  end
end

return M
