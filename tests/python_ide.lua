-- Requires the plugins and Mason packages installed by this configuration.
-- Run from the repository: nvim --headless -i NONE -u NONE --cmd 'set loadplugins' '+luafile tests/python_ide.lua'
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
  local function choose_context_action(id, bufnr)
    bufnr = bufnr or source
    vim.api.nvim_set_current_win(vim.fn.bufwinid(bufnr))
    local menus = require('config.context_menu')
    local index
    for i, item in ipairs(menus.items()) do if item.id == id then index = i - 1 end end
    assert(index, 'Missing context action: ' .. id)
    menus.open()
    local prompt = vim.api.nvim_get_current_buf()
    local picker = require('telescope.actions.state').get_current_picker(prompt)
    wait_for('Context menu did not populate', function() return picker.manager and picker.manager:num_results() > index end)
    picker:set_selection(index)
    require('telescope.actions').select_default(prompt)
    wait_for('Context action did not restore its origin', function() return vim.api.nvim_get_current_buf() == bufnr end)
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
  assert(menu_text:find('documentation', 1, true), 'Documentation missing from Which Key menu: ' .. menu_text)
  assert(menu_text:find('breakpoint', 1, true), 'Breakpoint missing from Which Key menu')
  local menus = require('config.context_menu')
  local code_items = menus.items()
  local code_ids = {}
  for _, item in ipairs(code_items) do code_ids[item.id] = true end
  assert(code_ids['lsp.hover'] and code_ids['lsp.definition'], 'Missing common Python LSP actions')
  assert(not code_ids['dap.next'] and not code_ids['dap.refresh'], 'Paused actions must be hidden before launching')
  assert(vim.o.mousemodel == 'extend', 'Native popup still competes for right-click')
  assert(vim.fn.maparg('<RightMouse>', 'n', false, true).buffer == 0, 'Right-click must be shared, not buffer-local')
  assert(vim.fn.maparg('<RightRelease>', 'n') == '<Nop>', 'Mouse release must not trigger another menu')
  local dap = require('dap')
  vim.api.nvim_win_set_cursor(0, { 8, 0 })
  choose_context_action('dap.breakpoint')
  wait_for('Context menu did not place the breakpoint', function()
    local points = require('dap.breakpoints').get(source)[source] or {}
    return #points == 1 and points[1].line == 8
  end)
  choose_context_action('dap.breakpoint')
  wait_for('Context menu did not remove the breakpoint', function()
    return #(require('dap.breakpoints').get(source)[source] or {}) == 0
  end)
  choose_context_action('dap.breakpoint')
  wait_for('Context menu did not restore the breakpoint', function()
    return #(require('dap.breakpoints').get(source)[source] or {}) == 1
  end)
  -- LSP callbacks also accept their own optional arguments, not the menu context.
  local original_rename, renamed = vim.lsp.buf.rename, false
  vim.lsp.buf.rename = function(...)
    assert(select('#', ...) == 0, 'Context leaked into the LSP rename argument')
    renamed = true
  end
  choose_context_action('lsp.rename')
  wait_for('Rename action was not invoked', function() return renamed end)
  vim.lsp.buf.rename = original_rename
  local input = vim.ui.input
  vim.ui.input = function(_, callback) callback('"Ada Lovelace"') end
  local original_notify = vim.notify
  vim.notify = function(message, ...)
    assert(not tostring(message):find('Python: ', 1, true), 'Launch must not display the interpreter notification')
    return original_notify(message, ...)
  end
  action('a')
  vim.notify = original_notify
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
  local context = require('config.context_menu')
  assert(vim.fn.maparg('<RightMouse>', 'n', false, true).callback, 'Missing mouse context menu')
  require('dapui').elements.watches.add('total')
  local options = context.items(context.context())
  local edit_index
  for index, item in ipairs(options) do if item.id == 'dap.edit' then edit_index = index - 1 end end
  assert(edit_index, 'Missing variable editing action')
  local answers = { 'total', '99' }
  local original_input = vim.ui.input
  vim.ui.input = function(_, callback) callback(table.remove(answers, 1)) end
  -- Select the edit action in the actual floating menu, preserving the source window.
  context.open()
  local prompt = vim.api.nvim_get_current_buf()
  assert(vim.bo[prompt].filetype == 'TelescopePrompt', 'Context menu did not open')
  local picker = require('telescope.actions.state').get_current_picker(prompt)
  wait_for('Context menu did not populate', function() return picker.manager and picker.manager:num_results() > 1 end)
  picker:set_selection(edit_index)
  require('telescope.actions').select_default(prompt)
  wait_for('Context menu did not edit the variable', function() return evaluate('total') == '99' end)
  vim.ui.input = original_input
  wait_for('Variables panel was not refreshed after editing', function()
    return table.concat(vim.api.nvim_buf_get_lines(panel, 0, -1, false), '\n'):find('99', 1, true) ~= nil
  end)
  -- A REPL assignment must also be refreshable without stepping the program.
  local assigned = false
  session:evaluate({ expression = 'total = 123', context = 'repl', frameId = session.current_frame.id }, function(err)
    assert(not err, vim.inspect(err))
    assigned = true
  end)
  wait_for('REPL assignment failed', function() return assigned end)
  require('config.debug_actions').refresh()
  wait_for('Manual refresh did not update the variables', function()
    return table.concat(vim.api.nvim_buf_get_lines(panel, 0, -1, false), '\n'):find('123', 1, true) ~= nil
  end)
  local watch_panel
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buffer].filetype == 'dapui_watches' then watch_panel = buffer; break end
  end
  assert(watch_panel, 'Watches panel not found')
  wait_for('Manual refresh did not update Watches', function()
    return table.concat(vim.api.nvim_buf_get_lines(watch_panel, 0, -1, false), '\n'):find('123', 1, true) ~= nil
  end)
  choose_context_action('dap.next', panel)
  wait_for('Step over did not reach the next line', function()
    return session.stopped_thread_id and session.current_frame and session.current_frame.line == 9
  end)
  choose_context_action('dap.continue', panel)
  wait_for('Session did not finish', function() return dap.session() == nil end)
  assert(vim.api.nvim_buf_is_valid(panel), 'Keep debug results available')
  local console = require('dapui').elements.console.buffer()
  local console_window = vim.fn.bufwinid(console)
  assert(console_window ~= -1, 'Application console is not visible')
  vim.api.nvim_set_current_win(console_window)
  wait_for('Console did not open at the first line', function()
    return vim.api.nvim_win_get_cursor(console_window)[1] == 1
  end)
  vim.cmd('normal! G')
  vim.api.nvim_set_current_win(vim.fn.bufwinid(source))
  vim.api.nvim_set_current_win(console_window)
  wait_for('Returning to the console did not restore the first line', function()
    return vim.api.nvim_win_get_cursor(console_window)[1] == 1
  end)

  action('l', panel)
  wait_for('Run last did not stop on the breakpoint', function()
    local active = dap.session()
    return active and active.stopped_thread_id and active.current_frame and active.current_frame.line == 8
  end)
  choose_context_action('dap.stop', panel)
  wait_for('Terminate did not stop the session', function() return dap.session() == nil end)
  vim.api.nvim_set_current_win(vim.fn.bufwinid(source))
  vim.bo.filetype = 'go'
  assert(vim.fn.maparg(' pb', 'n') == '', 'Python mappings leaked into Go')
  vim.bo.filetype = 'lua'
  assert(vim.fn.maparg(' pr', 'n') == '', 'Python mappings leaked into Lua')
  vim.fn.writefile({ 'module contextsmoke', '', 'go 1.22' }, work .. '/go.mod')
  vim.fn.writefile({ 'package main', '', 'func main() {}' }, work .. '/main.go')
  vim.cmd.edit(work .. '/main.go')
  local go_buffer = vim.api.nvim_get_current_buf()
  wait_for('gopls did not attach', function() return #vim.lsp.get_clients({ bufnr = go_buffer, name = 'gopls' }) > 0 end)
  local go_ids = {}
  for _, item in ipairs(menus.items()) do go_ids[item.id] = true end
  assert(go_ids['lsp.hover'] and go_ids['lsp.rename'] and go_ids['lsp.codeAction'], 'Go must use the same LSP menu')
  assert(not go_ids['dap.run'], 'Do not offer unconfigured Go debugging')
  assert(vim.fn.maparg(' m', 'n', false, true).buffer == 0, 'Common keyboard entry missing')
  -- An independent provider (future DB/plugin integration) shares the same picker.
  menus.register('integration-test', { priority = 1, actions = function(ctx)
    if ctx.bufnr ~= go_buffer then return {} end
    return { { id = 'test.extension', group = 'Extension', label = 'Action du fournisseur de test', run = function(origin)
      assert(origin.bufnr == go_buffer)
      vim.api.nvim_buf_set_var(origin.bufnr, 'context_test_done', true)
    end } }
  end })
  menus.mouse({ winid = vim.api.nvim_get_current_win(), line = 3, column = 8 })
  local popup = vim.api.nvim_get_current_buf()
  assert(vim.bo[popup].filetype == 'TelescopePrompt')
  local extension_picker = require('telescope.actions.state').get_current_picker(popup)
  wait_for('Extension action missing from picker', function() return extension_picker.manager and extension_picker.manager:num_results() > 0 end)
  extension_picker:set_selection(0)
  require('telescope.actions').select_default(popup)
  wait_for('Extension callback did not run in original buffer', function() return vim.b[go_buffer].context_test_done end)
  assert(vim.api.nvim_win_get_cursor(0)[2] == 7, 'Right-click lost the symbol column')
  menus.unregister('integration-test')
  local cancelled, calls = false, 0
  vim.ui.select({ 'cancel me' }, { prompt = 'Cancellation test' }, function(item)
    assert(item == nil)
    cancelled = true
    calls = calls + 1
  end)
  require('telescope.actions').close(vim.api.nvim_get_current_buf())
  wait_for('Popup cancellation was not delivered', function() return cancelled end)
  assert(calls == 1, 'Cancellation callback called more than once')
  print('IDE/menu OK: Python and Go LSP, providers, cancellation; project venv, dependency documentation, breakpoint, arguments, variables, panels, step, continue, rerun, terminate, buffer isolation')
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
