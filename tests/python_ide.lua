-- Requires the plugins and Mason packages installed by this configuration.
-- Run from the repository: nvim --headless -u NONE --cmd 'set loadplugins' '+luafile tests/python_ide.lua'
local repo = vim.fn.getcwd()
local work = vim.fn.tempname()
vim.fn.mkdir(work, 'p')
local original_env = { VIRTUAL_ENV = vim.env.VIRTUAL_ENV, CONDA_PREFIX = vim.env.CONDA_PREFIX }
vim.env.VIRTUAL_ENV = nil
vim.env.CONDA_PREFIX = nil
local function wait_for(message, condition)
  assert(vim.wait(20000, condition, 50), message)
end
local function run()
  vim.opt.rtp:prepend(repo)
  vim.opt.rtp:prepend(vim.fn.stdpath('data') .. '/lazy/lazy.nvim')
  local lazy = require('lazy')
  local setup = lazy.setup
  lazy.setup = function(spec, opts)
    opts.install = { missing = false }
    opts.change_detection = { enabled = false }
    opts.lockfile = work .. '/lazy-lock.json'
    return setup(spec, opts)
  end
  vim.opt.rtp:prepend(vim.fn.stdpath('data') .. '/lazy/nvim-treesitter')
  require('nvim-treesitter').install = function() end
  vim.cmd.source(repo .. '/init.lua')
  vim.api.nvim_exec_autocmds('VimEnter', {})
  wait_for('Which Key did not initialize', function() return require('which-key.config').loaded end)
  local venv = work .. '/.venv'
  local result = vim.system({ 'uv', 'venv', '--no-project', '--python', vim.fn.exepath('python3'), venv }, {
    env = { UV_CACHE_DIR = work .. '/uv-cache' },
  }):wait()
  assert(result.code == 0, result.stderr)
  local interpreter = venv .. '/bin/python'
  local site = vim.system({ interpreter, '-c', 'import sysconfig; print(sysconfig.get_path("purelib"))' }):wait()
  assert(site.code == 0, site.stderr)
  vim.fn.writefile({ 'def increment(value: int) -> int:', '    """Increment from the project virtualenv."""', '    return value + 2' }, vim.trim(site.stdout) .. '/ide_dependency.py')
  vim.fn.writefile({ '[project]', 'name = "ide-smoke"', 'version = "0.0.0"' }, work .. '/pyproject.toml')
  local program = work .. '/main.py'
  vim.fn.writefile({
    'from ide_dependency import increment',
    'import sys',
    '',
    'def greet(name: str) -> str:',
    '    """Return a friendly message."""',
    '    message = f"Hello {name}"',
    '    total = increment(40)',
    '    print(message, total, sys.executable)',
    '    return message',
    '',
    'result = greet(sys.argv[1] if len(sys.argv) > 1 else "Neovim")',
  }, program)
  vim.cmd.edit(program)
  local source = vim.api.nvim_get_current_buf()
  local python = require('config.python')
  assert(python.root(source) == work)
  assert(python.executable(work) == interpreter)
  vim.env.VIRTUAL_ENV = work .. '/missing'
  assert(python.executable(work) == interpreter, 'Ignore invalid activated environment')
  vim.env.VIRTUAL_ENV = nil
  wait_for('Pyright did not attach', function()
    return #vim.lsp.get_clients({ bufnr = source, name = 'pyright' }) == 1
  end)
  local client = vim.lsp.get_clients({ bufnr = source, name = 'pyright' })[1]
  assert(client.config.settings.python.pythonPath == interpreter)
  local function hover(line, character)
    local response = client:request_sync('textDocument/hover', {
      textDocument = { uri = vim.uri_from_bufnr(source) }, position = { line = line, character = character },
    }, 15000, source)
    assert(response and response.result, 'Missing Python hover documentation')
    return vim.inspect(response.result)
  end
  assert(hover(10, 11):find('Return a friendly message', 1, true))
  local dependency_doc = hover(0, 29)
  assert(dependency_doc:find('Increment from the project virtualenv', 1, true), 'Pyright must resolve project dependencies: ' .. dependency_doc)
  assert(vim.fn.maparg(' ph', 'n', false, true).buffer == 1)
  assert(vim.fn.maparg(' ds', 'n', false, true).desc == 'LSP: [D]ocument [S]ymbols')
  local function action(key, bufnr)
    bufnr = bufnr or source
    local win = vim.fn.bufwinid(bufnr)
    if win ~= -1 then vim.api.nvim_set_current_win(win) else vim.api.nvim_set_current_buf(bufnr) end
    local mapping = vim.fn.maparg(' p' .. key, 'n', false, true)
    assert(mapping.callback, 'Missing menu action ' .. key)
    mapping.callback()
  end
  local menu_text = ''
  vim.defer_fn(function()
    local view = require('which-key.view').view
    if view and view.buf and vim.api.nvim_buf_is_valid(view.buf) then
      menu_text = table.concat(vim.api.nvim_buf_get_lines(view.buf, 0, -1, false), '\n')
    end
    vim.api.nvim_feedkeys(vim.keycode('<Esc>'), 'n', false)
  end, 250)
  require('which-key').show({ keys = ' p', mode = 'n' })
  assert(menu_text:find('Documentation', 1, true), 'Documentation missing from Which Key menu: ' .. menu_text)
  assert(menu_text:find('breakpoint', 1, true), 'Breakpoint missing from Which Key menu')
  local dap = require('dap')
  vim.api.nvim_win_set_cursor(0, { 8, 0 })
  action('b')
  assert(require('dap.breakpoints').get(source)[source][1].line == 8)
  local input = vim.ui.input
  vim.ui.input = function(_, callback) callback('"Ada Lovelace"') end
  action('a')
  vim.ui.input = input
  wait_for('Program did not stop on the breakpoint', function()
    local session = dap.session()
    return session and session.stopped_thread_id and session.current_frame and session.current_frame.line == 8
  end)
  local session = dap.session()
  assert(session.config.pythonPath == interpreter)
  assert(session.config.cwd == work)
  assert(session.config.args[1] == 'Ada Lovelace')
  local function evaluate(expression)
    local done, value = false, nil
    session:request('evaluate', { expression = expression, frameId = session.current_frame.id, context = 'watch' }, function(err, response)
      assert(not err, vim.inspect(err))
      value = response.result
      done = true
    end)
    wait_for('Evaluation timed out', function() return done end)
    return value
  end
  assert(evaluate('total') == '42')
  assert(evaluate('message'):find('Hello Ada Lovelace', 1, true))
  local panel
  wait_for('Variables panel did not open', function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local bufnr = vim.api.nvim_win_get_buf(win)
      if vim.bo[bufnr].filetype == 'dapui_scopes' then panel = bufnr; return true end
    end
    return false
  end)
  wait_for('Variables are missing from the scopes panel', function()
    return table.concat(vim.api.nvim_buf_get_lines(panel, 0, -1, false), '\n'):find('total', 1, true) ~= nil
  end)
  vim.api.nvim_set_current_win(vim.fn.bufwinid(panel))
  assert(vim.fn.maparg(' pn', 'n', false, true).buffer == 1, 'Menu missing from debug panel')
  -- Editing is a per-line action: scope headers are not editable, variable rows are.
  local variable_line
  for index, line in ipairs(vim.api.nvim_buf_get_lines(panel, 0, -1, false)) do
    if line:match('total.*42') then variable_line = index; break end
  end
  assert(variable_line, 'Variable row not found')
  vim.api.nvim_win_set_cursor(0, { variable_line, 0 })
  local prompt_callback
  local set_prompt_callback = vim.fn.prompt_setcallback
  vim.fn.prompt_setcallback = function(buffer, callback)
    if buffer == panel then prompt_callback = callback end
    return set_prompt_callback(buffer, callback)
  end
  vim.fn.maparg('e', 'n', false, true).callback()
  wait_for('Variable edit did not create a prompt', function() return prompt_callback ~= nil end)
  vim.fn.prompt_setcallback = set_prompt_callback
  prompt_callback('99')
  wait_for('Editing did not change the live variable', function() return evaluate('total') == '99' end)
  action('n', panel)
  wait_for('Step over did not reach the next line', function()
    return session.stopped_thread_id and session.current_frame and session.current_frame.line == 9
  end)
  action('c', panel)
  wait_for('Session did not finish', function() return dap.session() == nil end)
  assert(vim.api.nvim_buf_is_valid(panel), 'Keep debug results available')
  action('l', panel)
  wait_for('Run last did not stop on the breakpoint', function()
    local active = dap.session()
    return active and active.stopped_thread_id and active.current_frame and active.current_frame.line == 8
  end)
  action('q', panel)
  wait_for('Terminate did not stop the session', function() return dap.session() == nil end)
  vim.api.nvim_set_current_win(vim.fn.bufwinid(source))
  vim.bo.filetype = 'go'
  assert(vim.fn.maparg(' pb', 'n') == '', 'Python mappings leaked into Go')
  vim.bo.filetype = 'lua'
  assert(vim.fn.maparg(' pr', 'n') == '', 'Python mappings leaked into Lua')
  print('Python IDE OK: project venv, dependency documentation, breakpoint, arguments, variables, panels, step, continue, rerun, terminate, buffer isolation')
end
local ok, err = xpcall(run, debug.traceback)
for _, client in ipairs(vim.lsp.get_clients()) do client:stop(true) end
local loaded, dap = pcall(require, 'dap')
if loaded then dap.terminate() end
vim.env.VIRTUAL_ENV = original_env.VIRTUAL_ENV
vim.env.CONDA_PREFIX = original_env.CONDA_PREFIX
if ok then
  vim.fn.delete(work, 'rf')
  vim.cmd('qa!')
else
  io.stderr:write(err .. '\nFixture: ' .. work .. '\n')
  vim.cmd('cquit 1')
end
