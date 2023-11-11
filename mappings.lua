local M = {}

-- Your custom mappings
M.general = {
  n = {
    ["<C-n>"] = { "<cmd> Telescope <CR>", "Telescope" },
    ["<C-s>"] = { ":Telescope Files <CR>", "Telescope Files" },
    ["<M-j>"] = { "mz:m+<CR>`z", "Move line down" },
    ["<M-k>"] = { "mz:m-2<CR>`z", "Move line up" },
  },

  v = {
    ["<M-j>"] = { ":m'>+<CR>`<my`>mzgv`yo`z", "Move lines down" },
    ["<M-k>"] = { ":m'<-2<CR>`>my`<mzgv`yo`z", "Move lines up" },
  },
}

return M
