##../../dash
@create_buffer_inspect+=
local inspect_buf = vim.api.nvim_create_buf(false, true)

@put_inspect_result_in_inspect_buffer+=
vim.api.nvim_buf_set_lines(inspect_buf, 0, -1, true, {
  vim.inspect(dash_inspect_result)
})

@create_float_window_inspect+=
local opts = {
	relative = "cursor",
  row = 1,
  col = 1,
	width = vim.api.nvim_strwidth(vim.inspect(dash_inspect_result)),
	height = 1,
	style = 'minimal'
}

local win = vim.api.nvim_open_win(inspect_buf, false, opts)

@implement+=
function M._close_preview_autocmd(events, winnr)
  vim.api.nvim_command("autocmd "..table.concat(events, ',').." <buffer> ++once lua pcall(vim.api.nvim_win_close, "..winnr..", true)")
end

@register_close_float_window_inspect+=
M._close_preview_autocmd({"CursorMoved", "CursorMovedI", "BufHidden", "BufLeave"}, win)
