local plugins = {
  {
    "hashivim/vim-terraform",
    config = function()
      vim.cmd [[let g:terraform_fmt_on_save=1]]
      vim.cmd [[let g:terraform_align=1]]
    end,
    ft = "terraform",
    lazy = true,
  },
  {
    "christianrondeau/vim-base64",
    config = function()
      vim.api.nvim_create_user_command("Base64Encode", function(opts)
        local range = opts.line1 .. "," .. opts.line2
        vim.cmd(range .. "call base64#v_btoa()")
      end, { range = true })

      vim.api.nvim_create_user_command("Base64Decode", function(opts)
        local range = opts.line1 .. "," .. opts.line2
        vim.cmd(range .. "call base64#v_atob()")
      end, { range = true })
    end,
    lazy = false,
  },
  { "ruanyl/vim-gh-line", lazy = false },
  {
    dir = vim.fn.stdpath "config" .. "/lua/custom/configs/mynotes.vim/",
    lazy = false,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "html",
        "css",
        "bash",
        "python",
        "java",
        "yaml",
        "sql",
        "promql",
        "csv",
        "c",
        "lua",
        "vim",
        "vimdoc",
        "query",
      },
    },
  },
  {
    -- https://mason-registry.dev/registry/list
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "lua-language-server",
        "html-lsp",
        "prettier",
        "stylua",
        "bash-language-server",
        "shfmt",
        "shellcheck",
        "pyright",
        "black",
        "ansible-language-server",
        "dockerfile-language-server",
        "deno",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",

    dependencies = {
      "jose-elias-alvarez/null-ls.nvim",
      config = function()
        require "custom.configs.null-ls"
      end,
    },

    config = function()
      require "plugins.configs.lspconfig"
      require "custom.configs.lspconfig"
    end,
  },

  {
    -- Adds git related signs to the gutter, as well as utilities for managing changes
    "lewis6991/gitsigns.nvim",
    opts = {
      -- See `:help gitsigns.txt`
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
      },
      on_attach = function(bufnr)
        vim.keymap.set(
          "n",
          "<leader>hp",
          require("gitsigns").preview_hunk,
          { buffer = bufnr, desc = "Preview git hunk" }
        )

        -- don't override the built-in and fugitive keymaps
        local gs = package.loaded.gitsigns
        vim.keymap.set({ "n", "v" }, "]c", function()
          if vim.wo.diff then
            return "]c"
          end
          vim.schedule(function()
            gs.next_hunk()
          end)
          return "<Ignore>"
        end, { expr = true, buffer = bufnr, desc = "Jump to next hunk" })
        vim.keymap.set({ "n", "v" }, "[c", function()
          if vim.wo.diff then
            return "[c"
          end
          vim.schedule(function()
            gs.prev_hunk()
          end)
          return "<Ignore>"
        end, { expr = true, buffer = bufnr, desc = "Jump to previous hunk" })
      end,
    },
  },
  {
    "toppair/peek.nvim",
    build = "deno task --quiet build:fast",
    keys = {
      {
        "<leader>op",
        function()
          local peek = require "peek"
          if peek.is_open() then
            peek.close()
          else
            peek.open()
          end
        end,
        desc = "Peek (Markdown Preview)",
      },
    },
    opts = { theme = "dark", app = "webview" },
  },
  {
    "NvChad/nvim-colorizer.lua",
    opts = {
      user_default_options = {
        names = false,
      },
    },
  },
}

return plugins
