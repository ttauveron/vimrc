return {
  {
    'mfussenegger/nvim-dap',
    ft = 'python',
    dependencies = {
      'mfussenegger/nvim-dap-python',
      { 'rcarriga/nvim-dap-ui', dependencies = { 'nvim-neotest/nvim-nio' } },
      {
        'jay-babu/mason-nvim-dap.nvim',
        dependencies = { 'williamboman/mason.nvim' },
      },
      'folke/which-key.nvim',
    },
    config = function()
      require('config.python_debug').setup()
    end,
  },
}
