local M = { priority = 30 }

function M.actions(context)
  -- Reading a Go/Lua/SQL file must not load or initialize the debugger.
  local dap = package.loaded.dap
  if not dap then return {} end
  local ft = context.filetype
  local panel = ft:match('^dapui_') or ft == 'dap-repl' or ft == 'dap-terminal'
  local configurations = dap.configurations[ft]
  local source = ft == 'python' or (type(configurations) == 'table' and #configurations > 0)
  if not panel and not source then return {} end
  local session = dap.session()
  local paused = session and session.stopped_thread_id and session.current_frame
  local items = {}
  local function add(id, label, run)
    items[#items + 1] = { id = 'dap.' .. id, label = label, group = 'Debug', run = function() run() end }
  end
  local function mapped(key)
    return function()
      local mapping = vim.fn.maparg(key, 'n', false, true)
      if mapping.callback then mapping.callback() end
    end
  end
  if source then
    add('breakpoint', 'Toggle breakpoint', dap.toggle_breakpoint)
    add('condition', 'Conditional breakpoint…', function()
      vim.ui.input({ prompt = 'Breakpoint condition: ' }, function(condition)
        if condition and condition ~= '' then dap.set_breakpoint(condition) end
      end)
    end)
    if not session then
      if ft == 'python' then
        add('run', 'Run current file', function() require('config.python_debug').launch(false) end)
        add('args', 'Run with arguments…', function() require('config.python_debug').launch(true) end)
      else
        add('run', 'Select configuration and run…', dap.continue)
      end
    end
    if ft == 'python' then
      add('interpreter', 'View / select Python interpreter…', function() require('config.python').select(context.bufnr) end)
    end
  end
  if ft == 'dapui_scopes' and paused then
    add('expand', 'Expand / collapse variable or scope', mapped('<CR>'))
  elseif ft == 'dapui_watches' then
    add('watch-add', 'Add watch expression…', function()
      vim.ui.input({ prompt = 'Watch expression: ' }, function(expression)
        if expression and expression ~= '' then require('dapui').elements.watches.add(expression) end
      end)
    end)
    if paused then add('expand', 'Expand / collapse value', mapped('<CR>')) end
    add('watch-remove', 'Remove selected watch', mapped('d'))
  elseif ft == 'dapui_stacks' and paused then
    add('frame', 'Select stack frame', mapped('o'))
    add('expand', 'Expand / collapse stack', mapped('<CR>'))
  elseif ft == 'dap-repl' then
    add('repl-input', 'Enter a console command', function() vim.cmd('startinsert!') end)
  end
  if paused then
    if session.capabilities.supportsSetExpression then
      add('edit', 'Edit variable / expression…', require('config.debug_actions').edit)
    end
    add('refresh', 'Refresh variables and watches', require('config.debug_actions').refresh)
    add('continue', 'Continue execution', dap.continue)
    add('next', 'Step over', dap.step_over)
    add('into', 'Step into', dap.step_into)
    add('out', 'Step out', dap.step_out)
  elseif session then
    add('pause', 'Pause execution', dap.pause)
  end
  if session then add('stop', 'Stop execution', dap.terminate) end
  add('ui', 'Toggle debug panels', function() require('dapui').toggle() end)
  return items
end

return M
