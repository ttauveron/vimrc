-- Common entry point. Providers supply actions; this module owns presentation/input.
local M = {}
local providers = {}

-- provider = { priority = number, actions = function(context) -> action[] }
-- action = { id = string, label = string, group = string?, run = function(context), enabled = boolean? }
function M.register(id, provider)
  assert(type(id) == 'string' and type(provider.actions) == 'function')
  providers[id] = provider
end

function M.unregister(id) providers[id] = nil end

function M.context()
  return {
    winid = vim.api.nvim_get_current_win(), bufnr = vim.api.nvim_get_current_buf(),
    cursor = vim.api.nvim_win_get_cursor(0), filetype = vim.bo.filetype,
  }
end

function M.items(context)
  context = context or M.context()
  local ordered, result, seen = {}, {}, {}
  for id, provider in pairs(providers) do ordered[#ordered + 1] = { id = id, provider = provider } end
  table.sort(ordered, function(a, b)
    local ap, bp = a.provider.priority or 50, b.provider.priority or 50
    return ap == bp and a.id < b.id or ap < bp
  end)
  for _, entry in ipairs(ordered) do
    for _, action in ipairs(entry.provider.actions(context) or {}) do
      if action.enabled ~= false and not seen[action.id] then
        assert(action.id and action.label and type(action.run) == 'function', 'Invalid context action')
        seen[action.id] = true
        result[#result + 1] = action
      end
    end
  end
  return result
end

-- Also implements vim.ui.select so LSP code actions and cooperating plugins use
-- the same searchable popup. Cancellation calls the consumer exactly once.
function M.select(items, opts, on_choice)
  opts = opts or {}
  if #items == 0 then on_choice(nil, nil); return end
  local context, completed = M.context(), false
  local function finish(item, index)
    if completed then return end
    completed = true
    vim.schedule(function()
      if vim.api.nvim_win_is_valid(context.winid)
        and vim.api.nvim_win_get_buf(context.winid) == context.bufnr then
        vim.api.nvim_set_current_win(context.winid)
        local count = vim.api.nvim_buf_line_count(context.bufnr)
        local row = math.min(context.cursor[1], count)
        local line = vim.api.nvim_buf_get_lines(context.bufnr, row - 1, row, false)[1] or ''
        vim.api.nvim_win_set_cursor(context.winid, { row, math.min(context.cursor[2], #line) })
        on_choice(item, index)
      else
        on_choice(nil, nil)
      end
    end)
  end
  local entries = {}
  for index, item in ipairs(items) do
    local label = opts.format_item and opts.format_item(item) or tostring(item)
    entries[#entries + 1] = { value = item, index = index, display = label, ordinal = label }
  end
  require('telescope.pickers').new(require('telescope.themes').get_dropdown({
    prompt_title = opts.prompt or 'Context actions', previewer = false,
    layout_config = { width = 0.65 },
  }), {
    finder = require('telescope.finders').new_table({ results = entries, entry_maker = function(entry) return entry end }),
    sorter = require('telescope.config').values.generic_sorter({}),
    attach_mappings = function(prompt, map)
      for _, mode in ipairs({ 'i', 'n' }) do
        map(mode, '<Esc>', function() require('telescope.actions').close(prompt) end)
      end
      vim.api.nvim_create_autocmd('BufWipeout', { buffer = prompt, once = true, callback = function() finish(nil, nil) end })
      require('telescope.actions').select_default:replace(function()
        local entry = require('telescope.actions.state').get_selected_entry()
        finish(entry and entry.value, entry and entry.index)
        require('telescope.actions').close(prompt)
      end)
      return true
    end,
  }):find()
end

function M.open()
  if vim.bo.filetype == 'TelescopePrompt' then return end
  local context = M.context()
  M.select(M.items(context), {
    prompt = 'Actions: ' .. (context.filetype ~= '' and context.filetype or 'file'),
    format_item = function(action) return (action.group and action.group .. ' · ' or '') .. action.label end,
  }, function(action)
    if action then
      -- Capabilities/session state may have changed while the menu was open.
      for _, current in ipairs(M.items(context)) do
        if current.id == action.id then current.run(context); return end
      end
      vim.notify('This action is no longer available.', vim.log.levels.INFO)
    end
  end)
end

function M.mouse(position)
  local mouse = position or vim.fn.getmousepos()
  if mouse.winid == 0 or not vim.api.nvim_win_is_valid(mouse.winid) then return end
  local buffer = vim.api.nvim_win_get_buf(mouse.winid)
  if vim.bo[buffer].filetype == 'TelescopePrompt' then return end
  vim.api.nvim_set_current_win(mouse.winid)
  local row = math.max(1, math.min(mouse.line, vim.api.nvim_buf_line_count(buffer)))
  local line = vim.api.nvim_buf_get_lines(buffer, row - 1, row, false)[1] or ''
  vim.api.nvim_win_set_cursor(mouse.winid, { row, math.min(math.max(0, mouse.column - 1), #line) })
  M.open()
end

function M.setup()
  M.register('editor', require('config.context_actions.editor'))
  M.register('lsp', require('config.context_actions.lsp'))
  M.register('dap', require('config.context_actions.dap'))
  vim.ui.select = M.select
  vim.keymap.set('n', '<leader>m', M.open, { desc = 'Context actions' })
  vim.keymap.set('n', '<S-F10>', M.open, { desc = 'Context actions' })
  vim.api.nvim_create_user_command('ContextActions', M.open, { desc = 'Show context actions' })
  -- Disable Neovim's native PopUp (Inspect, etc.): a single owner of right-click.
  vim.opt.mousemodel = 'extend'
  -- Rapid repeated clicks arrive as 2-/3-/4-RightMouse, not RightMouse.
  -- Handle all of them so the native selection/popup cannot win alternate clicks.
  for _, count in ipairs({ '', '2-', '3-', '4-' }) do
    local press, release = '<' .. count .. 'RightMouse>', '<' .. count .. 'RightRelease>'
    vim.keymap.set('n', press, M.mouse, { desc = 'Context actions', silent = true })
    vim.keymap.set('i', press, function()
      local position = vim.fn.getmousepos()
      vim.cmd.stopinsert()
      vim.schedule(function() M.mouse(position) end)
    end, { desc = 'Context actions', silent = true })
    vim.keymap.set('x', press, '<Esc><Cmd>lua require("config.context_menu").mouse()<CR>', { desc = 'Context actions', silent = true })
    vim.keymap.set('t', press, [[<C-\><C-n><Cmd>lua require("config.context_menu").mouse()<CR>]], { desc = 'Context actions', silent = true })
    vim.keymap.set({ 'n', 'i', 'x', 't' }, release, '<Nop>', { silent = true })
  end
end

return M
