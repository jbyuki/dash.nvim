##../dash
@spawn_tex_instance+=
local finish_tex = function(code, signal)
  vim.schedule(function()
    @check_if_output_written
    if output_written then
      @close_output_split
      if done then
        done()
      end
    else
      finish()
    end
  end)
end

MAX_LINES = 100000
handle, err = vim.loop.spawn("cmd",
  {
    stdio = {stdin, stdout, stderr},
    args = {"/c pdflatex -interaction=nonstopmode " .. filename},
    cwd = ".",
  }, finish_tex)

@check_if_output_written+=
local output_written = false
for _, line in ipairs(output_lines) do
  if string.match(line, "^Output written on") then
    output_written = true
    break
  end
end 

@close_output_split+=
if execute_win and vim.api.nvim_win_is_valid(execute_win) then
  vim.api.nvim_win_close(execute_win, true)
  execute_win = nil
end
