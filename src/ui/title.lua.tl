##../little-runner
@script_variables+=
local out_counter = 1
@rename_output_buffer+=
local bufname = "Out #" .. out_counter
local oldbufnr = vim.fn.bufnr(bufname)
if oldbufnr ~= -1 then
  vim.api.nvim_command("bw " .. oldbufnr)
end
vim.api.nvim_buf_set_name(execute_buf, bufname)
out_counter = out_counter + 1
