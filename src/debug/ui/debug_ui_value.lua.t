##../../dash
@create_buffer_inspect+=
local inspect_buf = vim.api.nvim_create_buf(false, true)

@put_inspect_result_in_inspect_buffer+=
vim.api.nvim_buf_set_lines(inspect_buf, 0, -1, true, lines)

@retrieve_inspect_result+=
local lines = vim.split(vim.inspect(dash_inspect_result), "\r*\n")

@create_float_window_inspect+=
local max_width = 0
for _, line in ipairs(lines) do
  max_width = math.max(vim.api.nvim_strwidth(line), max_width)
end

local opts = {
	relative = "cursor",
  row = 1,
  col = 1,
	width = max_width,
	height = #lines,
	style = 'minimal'
}

local win = vim.api.nvim_open_win(inspect_buf, false, opts)

@implement+=
function M._close_preview_autocmd(events, winnr)
  vim.api.nvim_command("autocmd "..table.concat(events, ',').." <buffer> ++once lua pcall(vim.api.nvim_win_close, "..winnr..", true)")
end

@register_close_float_window_inspect+=
M._close_preview_autocmd({"CursorMoved", "CursorMovedI", "BufHidden", "BufLeave"}, win)
