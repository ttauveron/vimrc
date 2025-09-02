vim.filetype.add({
	extension = { mynotes = "markdown" },
})

-- Set the buffer flag *before* syntax loads
local grp = vim.api.nvim_create_augroup("mynotes_ft", { clear = true })
vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
	group = grp,
	pattern = "*.mynotes",
	callback = function()
		vim.b.is_mynotes = 1
	end,
})
