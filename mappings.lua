local M = {}

-- Your custom mappings
M.general = {
  n = {
    ["<C-n>"] = { "<cmd> Telescope <CR>", "Telescope" },
    ["<C-s>"] = { ":Telescope Files <CR>", "Telescope Files" },
    ["<M-j>"] = { "mz:m+<CR>`z", "Move line down" },
    ["<M-k>"] = { "mz:m-2<CR>`z", "Move line up" },
    ["<leader>/"] = {
      function()
        -- You can pass additional configuration to telescope to change theme, layout, etc.
        require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end,
      "[/] Fuzzily search in current buffer",
    },

    ["<leader>gf"] = { ":Telescope git_files <CR>", "Search [G]it [F]iles" },
    ["<leader>sf"] = { ":Telescope find_files <CR>", "[S]earch [F]iles" },
    ["<leader>sh"] = { ":Telescope help_tags <CR>", "[S]earch [H]elp" },
    ["<leader>sw"] = { ":Telescope grep_string <CR>", "[S]earch current [W]ord" },
    ["<leader>sg"] = { ":Telescope live_grep <CR>", "[S]earch by [G]rep" },
    ["<leader>sd"] = { ":Telescope diagnostics <CR>", "[S]earch [D]iagnostics" },
    ["<leader>sr"] = { ":Telescope resume <CR>", "[S]earch [R]esume" },
  },
  v = {
    ["<M-j>"] = { ":m'>+<CR>`<my`>mzgv`yo`z", "Move lines down" },
    ["<M-k>"] = { ":m'<-2<CR>`>my`<mzgv`yo`z", "Move lines up" },
  },
}

return M
