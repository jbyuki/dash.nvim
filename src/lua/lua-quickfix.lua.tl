##../little-runner
@parse_error_for_quickfix+=
if ft == "lua" then
  for line in vim.gsplit(data, "\r*\n") do
    if string.match(line, "^E%d+: Error while creating lua chunk: ") then
      @parse_all_informations_from_line
      @set_error_in_quickfix_window
    end
  end
end

@parse_all_informations_from_line+=
local errnum, fn, lnum, errmsg = string.match(line, "^E(%d+): Error while creating lua chunk: (.-%.lua):(%d+): (.*)")


@set_error_in_quickfix_window+=
vim.fn.setqflist({{
  filename = fn, 
  lnum = lnum, 
  nr = errnum,
  text = errmsg,
  type = 'E'
}})
open_quickfix = true

@open_quickfix+=
if open_quickfix then
  -- vim.api.nvim_command("copen")
end

@close_quickfix_if_open+=
vim.api.nvim_command("cclose")
vim.fn.setqflist({})
