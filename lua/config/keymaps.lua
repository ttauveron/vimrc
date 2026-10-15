-- [[ Basic Keymaps ]]

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Moving lines of text with Alt-j and Alt-k
vim.api.nvim_set_keymap('n', '<M-j>', "mz:m+<CR>`z", { noremap = true })
vim.api.nvim_set_keymap('n', '<M-k>', "mz:m-2<CR>`z", { noremap = true })

-- Ensure visual mode mappings work properly with `gv` to reselect the text
vim.api.nvim_set_keymap('v', '<M-j>', ":m'>+<CR>`<my`>mzgv`yo`z", { noremap = true })
vim.api.nvim_set_keymap('v', '<M-k>', ":m'<-2<CR>`>my`<mzgv`yo`z", { noremap = true })

vim.api.nvim_set_keymap('t', '<Esc>', [[<C-\><C-n>]], { noremap = true, silent = true })
