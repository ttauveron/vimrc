-- Compatibility bridge for the locked Telescope 0.1.x and Treesitter versions.
-- Keep isolated until these plugins are upgraded together.
local function patch_telescope_treesitter_compat()
  local ok, parsers = pcall(require, 'nvim-treesitter.parsers')
  if ok and not parsers.ft_to_lang then
    parsers.ft_to_lang = function(ft)
      return vim.treesitter.language.get_lang(ft) or ft
    end
  end

  local configs_ok = pcall(require, 'nvim-treesitter.configs')
  if not configs_ok then
    package.preload['nvim-treesitter.configs'] = function()
      return {
        is_enabled = function()
          return false
        end,
        get_module = function()
          return {}
        end,
      }
    end
  end
end

return patch_telescope_treesitter_compat
