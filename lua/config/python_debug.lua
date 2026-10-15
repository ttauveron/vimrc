local M = {}
local python = require('config.python')
local last_source
local has_run = false

local function notify(message)
  vim.notify(message, vim.log.levels.WARN, { title = 'Python' })
end

local function source_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].filetype == 'python' then return bufnr end
  if last_source and vim.api.nvim_buf_is_valid(last_source) then return last_source end
end

function M.launch(with_args)
  local dap = require('dap')
  if dap.session() then
    notify('Une session est deja active. Continuer avec Espace p c ou arreter avec Espace p q.')
    return
  end
  local bufnr = source_buffer()
  if not bufnr or vim.api.nvim_buf_get_name(bufnr) == '' then
    notify('Ouvrir et enregistrer un fichier Python avant de le lancer.')
    return
  end
  local root = python.root(bufnr)
  local interpreter = python.executable(root)
  if interpreter == '' or vim.fn.executable(interpreter) ~= 1 then
    notify('Choisir un interpreteur Python avec Espace p v.')
    return
  end
  local adapter = vim.fn.stdpath('data') .. '/mason/packages/debugpy/venv/bin/python'
  if vim.fn.executable(adapter) ~= 1 then
    notify('Le debogueur est en cours d’installation ou absent. Ouvrir :Mason et installer debugpy.')
    return
  end
  local function run(args)
    if not vim.api.nvim_buf_is_valid(bufnr) then return end
    local ok, err = pcall(vim.api.nvim_buf_call, bufnr, function() vim.cmd.update() end)
    if not ok then notify('Enregistrement impossible : ' .. err); return end
    last_source = bufnr
    has_run = true
    vim.notify('Python : ' .. interpreter .. '\nProjet : ' .. root)
    dap.run({
      type = 'python',
      request = 'launch',
      name = 'Python : ' .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':t'),
      program = vim.api.nvim_buf_get_name(bufnr),
      cwd = root,
      pythonPath = function() return python.executable(root) end,
      args = args,
      console = 'integratedTerminal',
      justMyCode = true,
    })
  end
  if with_args then
    vim.ui.input({ prompt = 'Arguments (guillemets acceptes) : ' }, function(input)
      if input == nil then return end
      local ok, args = pcall(require('dap.utils').splitstr, input)
      if not ok then notify('Arguments invalides : ' .. args); return end
      run(args)
    end)
  else
    run({})
  end
end

local function stopped(action)
  return function()
    local session = require('dap').session()
    if not session or not session.stopped_thread_id then
      notify('Le programme doit etre en pause sur un breakpoint.')
      return
    end
    action()
  end
end

function M.setup_buffer(bufnr)
  local dap = require('dap')
  local dapui = require('dapui')
  local is_python = vim.bo[bufnr].filetype == 'python'
  vim.b[bufnr].python_menu = true
  local function map(key, action, desc)
    vim.keymap.set('n', '<leader>p' .. key, action, { buffer = bufnr, silent = true, desc = desc })
  end
  require('which-key').add({ { '<leader>p', group = 'Python', buffer = bufnr } })
  map('r', function() M.launch(false) end, 'Lancer le fichier sous debogueur')
  map('a', function() M.launch(true) end, 'Lancer avec des arguments')
  map('c', function()
    if dap.session() then dap.continue() else M.launch(false) end
  end, 'Continuer / demarrer')
  map('n', stopped(dap.step_over), 'Ligne suivante')
  map('i', stopped(dap.step_into), 'Entrer dans la fonction')
  map('o', stopped(dap.step_out), 'Sortir de la fonction')
  map('e', stopped(dapui.eval), 'Inspecter la variable sous le curseur')
  map('x', stopped(function()
    vim.ui.input({ prompt = 'Expression Python : ' }, function(expression)
      if expression and expression ~= '' then dapui.eval(expression, { enter = true }) end
    end)
  end), 'Evaluer une expression')
  map('u', dapui.toggle, 'Afficher / masquer les panneaux')
  map('l', function()
    if dap.session() then notify('Arreter la session avant de relancer.'); return end
    if not has_run then notify('Lancer un fichier avec Espace p r avant de le relancer.'); return end
    if last_source and vim.api.nvim_buf_is_valid(last_source) then
      local ok, err = pcall(vim.api.nvim_buf_call, last_source, function() vim.cmd.update() end)
      if not ok then notify('Enregistrement impossible : ' .. err); return end
    end
    dap.run_last()
  end, 'Relancer la derniere execution')
  map('q', function()
    if dap.session() then dap.terminate() else notify('Aucune session active.') end
  end, 'Arreter le programme')
  if is_python then
    -- Leave room for both Gitsigns (priority 100) and a breakpoint (priority 21).
    vim.api.nvim_buf_call(bufnr, function() vim.opt_local.signcolumn = 'yes:2' end)
    map('h', function()
      if #vim.lsp.get_clients({ bufnr = bufnr, name = 'pyright' }) == 0 then
        notify('Le serveur Python demarre ou est absent. Verifier pyright dans :Mason.')
        return
      end
      vim.lsp.buf.hover({ border = 'rounded' })
    end, 'Documentation de la fonction')
    map('b', dap.toggle_breakpoint, 'Placer / retirer un breakpoint')
    map('B', function()
      vim.ui.input({ prompt = 'Condition du breakpoint : ' }, function(condition)
        if condition and condition ~= '' then dap.set_breakpoint(condition) end
      end)
    end, 'Breakpoint conditionnel')
    map('v', function() python.select(bufnr) end, 'Voir / choisir l’interpreteur Python')
  end
end

function M.setup()
  local dap = require('dap')
  require('mason').setup()
  -- Mason installs debugpy; dap-python owns adapter configuration.
  require('mason-nvim-dap').setup({ ensure_installed = { 'python' } })
  local adapter = vim.fn.stdpath('data') .. '/mason/packages/debugpy/venv/bin/python'
  require('dap-python').setup(adapter, { include_configs = false })

  vim.fn.sign_define('DapBreakpoint', { text = '●', texthl = 'DiagnosticError' })
  vim.fn.sign_define('DapBreakpointCondition', { text = '◆', texthl = 'DiagnosticWarn' })
  vim.fn.sign_define('DapBreakpointRejected', { text = '○', texthl = 'DiagnosticWarn' })
  vim.fn.sign_define('DapStopped', { text = '▶', texthl = 'DiagnosticOk', linehl = 'Visual' })

  require('dapui').setup({
    layouts = {
      {
        elements = {
          { id = 'scopes', size = 0.5 },
          { id = 'stacks', size = 0.25 },
          { id = 'watches', size = 0.25 },
        },
        size = 40,
        position = 'left',
      },
      {
        elements = { { id = 'console', size = 0.6 }, { id = 'repl', size = 0.4 } },
        size = 12,
        position = 'bottom',
      },
    },
    floating = { border = 'rounded' },
  })
  -- Keep the output panels open after termination.
  dap.listeners.after.event_initialized['python-ui'] = function() require('dapui').open() end

  local group = vim.api.nvim_create_augroup('PythonMenu', { clear = true })
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    callback = function(event)
      local ft = vim.bo[event.buf].filetype
      if ft == 'python' or ft:match('^dapui_') or ft == 'dap-repl' or ft == 'dap-terminal' then
        M.setup_buffer(event.buf)
      elseif vim.b[event.buf].python_menu then
        for _, key in ipairs({ 'r', 'a', 'c', 'n', 'i', 'o', 'e', 'x', 'u', 'l', 'q', 'h', 'b', 'B', 'v' }) do
          pcall(vim.keymap.del, 'n', '<leader>p' .. key, { buffer = event.buf })
        end
        vim.b[event.buf].python_menu = nil
      end
    end,
  })
  -- DAP may load while the first Python FileType event is already being handled.
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[bufnr].filetype == 'python' then M.setup_buffer(bufnr) end
  end
end

return M
