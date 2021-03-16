##../dash
@script_variables+=
local out_counter = 1
@rename_output_buffer+=

local bufname
while true do
  bufname = "Out #" .. out_counter
  local oldbufnr = vim.fn.bufnr(bufname)
  if oldbufnr == -1 then
    break
  end
  out_counter = out_counter + 1
end
vim.api.nvim_buf_set_name(execute_buf, bufname)
out_counter = out_counter + 1
