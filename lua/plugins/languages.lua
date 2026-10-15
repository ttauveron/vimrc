return {
  { 'chrisbra/csv.vim', lazy = false },
  {
    "fatih/vim-go",
    build = ":GoUpdateBinaries"
  },

  {
    'hashivim/vim-terraform',
    config = function()
      vim.g.terraform_fmt_on_save = 1
      vim.g.terraform_binary_path = 'tofu'
    end
  },

}
