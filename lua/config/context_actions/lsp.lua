return {
  priority = 20,
  actions = function(context)
    local result = {}
    local methods = {
      { 'hover', 'Show documentation', function() vim.lsp.buf.hover({ border = 'rounded' }) end },
      { 'definition', 'Go to definition', vim.lsp.buf.definition },
      { 'references', 'Find references', vim.lsp.buf.references },
      { 'implementation', 'Go to implementations', vim.lsp.buf.implementation },
      { 'rename', 'Rename symbol…', vim.lsp.buf.rename },
      { 'codeAction', 'Code actions and refactorings…', vim.lsp.buf.code_action },
      { 'formatting', 'Format file', function() vim.lsp.buf.format({ bufnr = context.bufnr }) end },
    }
    for _, method in ipairs(methods) do
      if #vim.lsp.get_clients({ bufnr = context.bufnr, method = 'textDocument/' .. method[1] }) > 0 then
        local run = method[3]
        result[#result + 1] = { id = 'lsp.' .. method[1], label = method[2], group = 'Code', run = function() run() end }
      end
    end
    return result
  end,
}
