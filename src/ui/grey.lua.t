##../dash
@put_grey_highlight_over+=
local grey_id = vim.api.nvim_create_namespace("")
local linecount = vim.api.nvim_buf_line_count(buf)
for i=1,linecount  do
  vim.api.nvim_buf_add_highlight(buf, grey_id, "NonText", i-1, 0, -1)
end

@if_no_output_clear_grey_highlight+=
if #output_lines == 0 then
  @clear_grey_highlight
end

@clear_grey_highlight+=
vim.api.nvim_buf_clear_namespace(buf, grey_id, 0, -1)
