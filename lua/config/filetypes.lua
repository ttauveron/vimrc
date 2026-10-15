-- Make *.tsv use the csv filetype
vim.filetype.add({
  extension = {
    mynotes = 'mynotes',
    tsv = 'csv',
    tf = 'terraform',
    tfvars = 'terraform-vars',
    hcl = 'hcl',
  },
  pattern = {
    ['.*%.auto%.tfvars'] = 'terraform-vars',
  },
})
vim.treesitter.language.register('markdown', 'mynotes')

vim.g.markdown_fenced_languages = {
  'bash=sh',
  'go',
  'lua',
  'python',
  'json',
  'javascript',
  'typescript',
  'terraform',
  'hcl',
  'yaml',
}

-- Ensure correct order: ftplugin first, then syntax
vim.cmd('filetype plugin on')
vim.cmd('syntax on')

-- Pre-set the delimiter for .tsv *before* syntax loads
vim.api.nvim_create_autocmd({ 'BufReadPre', 'BufNewFile' }, {
  pattern = '*.tsv',
  callback = function(ev)
    -- csv.vim uses b:delimiter; g:csv_delim also seeds it
    vim.b[ev.buf].delimiter = '\t'
    vim.b[ev.buf].csv_delim = '\t'
  end,
})
