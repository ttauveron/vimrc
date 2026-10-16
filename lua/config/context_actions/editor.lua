local M = { priority = 80 }

function M.actions(context)
  local items = {}
  if vim.bo[context.bufnr].buftype == '' then
    items[#items + 1] = { id = 'editor.diagnostics', label = 'Show line diagnostics', group = 'Editor', run = function() vim.diagnostic.open_float({ scope = 'line' }) end }
    if vim.bo[context.bufnr].modifiable then
      items[#items + 1] = { id = 'editor.save', label = 'Save file', group = 'Editor', run = function() vim.cmd('silent update') end }
    end
  end
  local mappings = vim.api.nvim_buf_get_keymap(context.bufnr, 'n')
  local described = {}
  for _, mapping in ipairs(mappings) do
    if mapping.desc and mapping.desc ~= '' and mapping.lhs ~= '<RightMouse>' then described[#described + 1] = mapping end
  end
  if #described > 0 then
    table.sort(described, function(a, b) return a.desc < b.desc end)
    items[#items + 1] = {
      id = 'editor.buffer-actions', label = 'More buffer actions…', group = 'Extensions',
      run = function()
        require('config.context_menu').select(described, {
          prompt = 'Extension actions',
          format_item = function(mapping) return mapping.desc .. '  [' .. mapping.lhs .. ']' end,
        }, function(mapping)
          if not mapping then return end
          if mapping.callback then mapping.callback()
          else vim.api.nvim_feedkeys(vim.keycode(mapping.lhs), 'm', false) end
        end)
      end,
    }
  end
  return items
end

return M
