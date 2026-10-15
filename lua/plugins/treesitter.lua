return {
  {
    'neovim-treesitter/nvim-treesitter',
    dependencies = {
      'neovim-treesitter/treesitter-parser-registry',
    },
    lazy = false,
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter').setup {
        install_dir = vim.fn.stdpath('data') .. '/site',
      }

      require('nvim-treesitter').install {
        'bash',
        'c',
        'cpp',
        'go',
        'javascript',
        'lua',
        'python',
        'rust',
        'terraform',
        'hcl',
        'tsx',
        'typescript',
        'vim',
        'vimdoc',
      }

      vim.api.nvim_create_autocmd('FileType', {
        pattern = {
          'bash',
          'c',
          'cpp',
          'go',
          'javascript',
          'lua',
          'python',
          'rust',
          'terraform',
          'terraform-vars',
          'hcl',
          'typescript',
          'tsx',
          'vim',
        },
        callback = function()
          vim.treesitter.start()
        end,
      })
    end,
  },
}
