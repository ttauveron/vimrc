local function replace_lines(bufnr, line1, line2, text)
  local lines = vim.split(text, "\n", { plain = true })
  vim.api.nvim_buf_set_lines(bufnr, line1 - 1, line2, false, lines)
end

local function get_visual_bounds()
  local s = vim.fn.getpos("'<")
  local e = vim.fn.getpos("'>")

  local srow, scol = s[2], s[3]
  local erow, ecol = e[2], e[3]

  if srow > erow or (srow == erow and scol > ecol) then
    srow, erow = erow, srow
    scol, ecol = ecol, scol
  end

  return srow, scol, erow, ecol
end

local function get_text_from_visual(bufnr, srow, scol, erow, ecol)
  local lines = vim.api.nvim_buf_get_lines(bufnr, srow - 1, erow, false)
  if #lines == 0 then
    return ""
  end

  if #lines == 1 then
    return string.sub(lines[1], scol, ecol)
  end

  lines[1] = string.sub(lines[1], scol)
  lines[#lines] = string.sub(lines[#lines], 1, ecol)
  return table.concat(lines, "\n")
end

local function replace_visual_text(bufnr, srow, scol, erow, ecol, replacement)
  local new_lines = vim.split(replacement, "\n", { plain = true })
  vim.api.nvim_buf_set_text(bufnr, srow - 1, scol - 1, erow - 1, ecol, new_lines)
end

local function command_uses_current_visual_range(opts)
  local srow = vim.fn.getpos("'<")[2]
  local erow = vim.fn.getpos("'>")[2]
  if srow == 0 or erow == 0 then
    return false
  end
  return opts.line1 == math.min(srow, erow) and opts.line2 == math.max(srow, erow)
end

vim.api.nvim_create_user_command("Base64Encode", function(opts)
  local bufnr = 0

  if opts.range > 0 and command_uses_current_visual_range(opts) then
    local srow, scol, erow, ecol = get_visual_bounds()
    local text = get_text_from_visual(bufnr, srow, scol, erow, ecol)
    local encoded = vim.base64.encode(text)
    replace_visual_text(bufnr, srow, scol, erow, ecol, encoded)
    return
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, opts.line1 - 1, opts.line2, false)
  local text = table.concat(lines, "\n")
  local encoded = vim.base64.encode(text)
  replace_lines(bufnr, opts.line1, opts.line2, encoded)
end, { range = true })

vim.api.nvim_create_user_command("Base64Decode", function(opts)
  local bufnr = 0

  if opts.range > 0 and command_uses_current_visual_range(opts) then
    local srow, scol, erow, ecol = get_visual_bounds()
    local text = get_text_from_visual(bufnr, srow, scol, erow, ecol)

    local ok, decoded = pcall(vim.base64.decode, text)
    if not ok then
      vim.notify("Base64Decode: contenu invalide", vim.log.levels.ERROR)
      return
    end

    replace_visual_text(bufnr, srow, scol, erow, ecol, decoded)
    return
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, opts.line1 - 1, opts.line2, false)
  local text = table.concat(lines, "\n")

  local ok, decoded = pcall(vim.base64.decode, text)
  if not ok then
    vim.notify("Base64Decode: contenu invalide", vim.log.levels.ERROR)
    return
  end

  replace_lines(bufnr, opts.line1, opts.line2, decoded)
end, { range = true })
