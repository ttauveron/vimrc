-- Debugger operations shared by shortcuts and the common context-menu provider.
local M = {}

local function paused()
  local session = require('dap').session()
  if not session or not session.stopped_thread_id or not session.current_frame then
    vim.notify('Pause at a breakpoint before using this action.', vim.log.levels.WARN)
    return
  end
  return session
end

function M.refresh()
  local session = paused()
  if session then
    -- Request fresh scopes; DAP UI also reevaluates Watches on this response.
    session:_request_scopes(session.current_frame)
  end
end

function M.edit()
  local session = paused()
  if not session then return end
  local frame = session.current_frame.id
  local function still_paused()
    return require('dap').session() == session and session.stopped_thread_id
      and session.current_frame and session.current_frame.id == frame
  end
  local function failed(err)
    vim.notify('Unable to change value: ' .. (err.message or tostring(err)), vim.log.levels.ERROR)
  end
  vim.ui.input({ prompt = 'Variable or expression to edit: ', default = vim.fn.expand('<cword>') }, function(expression)
    if not expression or expression == '' or not still_paused() then return end
    session:request('evaluate', { expression = expression, frameId = frame, context = 'watch' }, function(err, response)
      if err then failed(err); return end
      if not still_paused() then return end
      vim.ui.input({ prompt = 'New value for ' .. expression .. ': ', default = response.result }, function(value)
        if value == nil or not still_paused() then return end
        session:request('setExpression', { expression = expression, value = value, frameId = frame }, function(set_err)
          if set_err then failed(set_err); return end
          if still_paused() then M.refresh() end
        end)
      end)
    end)
  end)
end

return M
