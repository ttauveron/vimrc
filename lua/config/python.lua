-- Share the project interpreter between Pyright and the debuggee.
local M = {}
local selected = {}

function M.root(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr or 0)
  local directory = name ~= '' and vim.fs.dirname(name) or vim.fn.getcwd()
  return vim.fs.root(directory, {
    'pyproject.toml', 'pyrightconfig.json', 'setup.py', 'setup.cfg',
    'requirements.txt', 'Pipfile', '.git',
  }) or directory
end

function M.executable(root)
  root = root or M.root()
  if selected[root] then
    return selected[root]
  end
  for _, env in ipairs({ 'VIRTUAL_ENV', 'CONDA_PREFIX' }) do
    local directory = vim.env[env]
    if directory and vim.fn.executable(directory .. '/bin/python') == 1 then
      return directory .. '/bin/python'
    end
  end
  for _, directory in ipairs({ '.venv', 'venv', 'env', '.env' }) do
    local candidate = root .. '/' .. directory .. '/bin/python'
    if vim.fn.executable(candidate) == 1 then
      return candidate
    end
  end
  return vim.fn.exepath('python3') ~= '' and vim.fn.exepath('python3') or vim.fn.exepath('python')
end

function M.before_init(_, config)
  -- Neovim already references this settings table when before_init runs.
  config.settings = config.settings or {}
  config.settings.python = config.settings.python or {}
  config.settings.python.pythonPath = M.executable(config.root_dir)
end

function M.select(bufnr)
  local root = M.root(bufnr)
  vim.ui.select({ 'Select interpreter', 'Auto-detect' }, {
    prompt = 'Python: ' .. M.executable(root),
  }, function(choice)
    if not choice then return end
    local function apply(path)
      selected[root] = path
      local python = M.executable(root)
      for _, client in ipairs(vim.lsp.get_clients({ name = 'pyright' })) do
        if client.config.root_dir == root then
          client.settings = vim.tbl_deep_extend('force', client.settings or {}, {
            python = { pythonPath = python },
          })
          client:notify('workspace/didChangeConfiguration', { settings = client.settings })
        end
      end
      vim.notify('Python: ' .. python)
    end
    if choice == 'Auto-detect' then
      apply(nil)
    else
      vim.ui.input({ prompt = 'Python interpreter: ', default = M.executable(root), completion = 'file' }, function(path)
        if not path then return end
        path = vim.fn.fnamemodify(vim.fn.expand(path), ':p')
        if vim.fn.executable(path) ~= 1 or vim.fn.isdirectory(path) == 1 then
          vim.notify('Python interpreter not found: ' .. path, vim.log.levels.ERROR)
          return
        end
        apply(path)
      end)
    end
  end)
end

return M
