return {
  {
    -- Theme inspired by Atom
    'drewtempelmeyer/palenight.vim',
    priority = 1000,
    config = function()
      vim.cmd.colorscheme 'palenight'
    end,
  },
  {
    -- Set lualine as statusline
    'nvim-lualine/lualine.nvim',
    -- See `:help lualine.txt`
    config = function()
      -- stylua: ignore
      local colors = {
        blue   = '#80a0ff',
        cyan   = '#79dac8',
        black  = '#080808',
        white  = '#c6c6c6',
        red    = '#ff5189',
        violet = '#d183e8',
        grey   = '#303030',
      }

      local bubbles_theme = {
        normal = {
          a = { fg = colors.black, bg = colors.violet },
          b = { fg = colors.white, bg = colors.grey },
          c = { fg = colors.white },
        },

        insert = { a = { fg = colors.black, bg = colors.blue } },
        visual = { a = { fg = colors.black, bg = colors.cyan } },
        replace = { a = { fg = colors.black, bg = colors.red } },

        inactive = {
          a = { fg = colors.white, bg = colors.black },
          b = { fg = colors.white, bg = colors.black },
          c = { fg = colors.white },
        },
      }

      require('lualine').setup {
        options = {
          theme = bubbles_theme,
          component_separators = { left = '', right = '' },
          section_separators = { left = '', right = '' },
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch', 'diff', 'diagnostics' },
          lualine_c = { 'filename' },
          lualine_x = { 'encoding', 'fileformat', 'filetype' },
          lualine_y = { 'progress' },
          lualine_z = { 'location' }
        },
        inactive_sections = {
          lualine_a = { 'filename' },
          lualine_b = {},
          lualine_c = {},
          lualine_x = {},
          lualine_y = {},
          lualine_z = { 'location' },
        },
        tabline = {},
        extensions = {},
      }
    end,
  },
  {
    -- Add indentation guides even on blank lines
    'lukas-reineke/indent-blankline.nvim',
    -- Enable `lukas-reineke/indent-blankline.nvim`
    -- See `:help ibl`
    main = 'ibl',
    opts = {},
  },
  {
    'gelguy/wilder.nvim',
    dependencies = { 'romgrk/fzy-lua-native' },
    config = function()
      local wilder = require('wilder')
      wilder.setup({ modes = { ':', '/', '?' } })
      -- Disable Python remote plugin
      wilder.set_option('use_python_remote_plugin', 0)

      wilder.set_option('pipeline', {
        wilder.branch(
          wilder.cmdline_pipeline({
            fuzzy = 1,
            fuzzy_filter = wilder.lua_fzy_filter(),
            debounce = 10,
          }),
          wilder.vim_search_pipeline()
        )
      })

      local gradient = {
        '#f4468f', '#fd4a85', '#ff507a', '#ff566f', '#ff5e63',
        '#ff6658', '#ff704e', '#ff7a45', '#ff843d', '#ff9036',
        '#f89b31', '#efa72f', '#e6b32e', '#dcbe30', '#d2c934',
        '#c8d43a', '#bfde43', '#b6e84e', '#aff05b'
      }

      for i, fg in ipairs(gradient) do
        gradient[i] = wilder.make_hl('WilderGradient' .. i, 'Pmenu', { { a = 1 }, { a = 1 }, { foreground = fg } })
      end

      local highlighters = {
        wilder.highlighter_with_gradient({
          wilder.pcre2_highlighter(),
          wilder.lua_fzy_highlighter(),
        }),
      }

      local popupmenu_renderer = wilder.popupmenu_renderer(
        wilder.popupmenu_border_theme({
          border = 'rounded',
          empty_message = wilder.popupmenu_empty_message_with_spinner(),
          highlighter = highlighters,
          highlights = {
            border = 'Normal',
            gradient = gradient,
          },
          left = {
            ' ',
          },
          right = {
            ' ',
            wilder.popupmenu_scrollbar(),
          },
        })
      )

      local wildmenu_renderer = wilder.wildmenu_renderer({
        highlighter = highlighters,
        separator = ' · ',
        left = { ' ', wilder.wildmenu_spinner(), ' ' },
        right = { ' ', wilder.wildmenu_index() },
      })

      wilder.set_option('renderer', wilder.renderer_mux({
        [':'] = popupmenu_renderer,
        ['/'] = wildmenu_renderer,
        substitute = wildmenu_renderer,
      }))
    end,
  },
  {
    'folke/which-key.nvim',
    config = function()
      -- document existing key chains
      -- after which-key loads
      local wk = require('which-key')

      wk.setup({ preset = "modern" })

      -- declare groups with the new spec
      wk.add({
        { "<leader>c",  group = "[C]ode" },
        { "<leader>d",  group = "[D]ocument" },
        { "<leader>g",  group = "[G]it" },
        { "<leader>h",  group = "More git" },
        { "<leader>r",  group = "[R]ename" },
        { "<leader>s",  group = "[S]earch" },
        { "<leader>w",  group = "[W]orkspace" },
        { "<leader>z",  group = "My stuff" },

        -- optional: hide the “group placeholder” entries (the checker suggests these)
        { "<leader>c_", hidden = true },
        { "<leader>d_", hidden = true },
        { "<leader>g_", hidden = true },
        { "<leader>h_", hidden = true },
        { "<leader>r_", hidden = true },
        { "<leader>s_", hidden = true },
        { "<leader>w_", hidden = true },
        { "<leader>z_", hidden = true },
      })
    end,
  },
}
