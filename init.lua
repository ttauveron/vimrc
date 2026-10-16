-- Leaders must be set before loading plugins or defining mappings.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.vim_base64_disable_default_key_mappings = 1

require('config.filetypes')
require('config.lazy')
require('config.options')
require('config.keymaps')
require('config.context_menu').setup()
require('config.autocmds')
require('custom.commands')
