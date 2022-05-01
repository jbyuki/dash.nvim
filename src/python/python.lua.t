##../dash
@spawn_python_instance+=
if vim.fn.has('win32') == 1 then
  handle, err = vim.loop.spawn(vim.g.python3_host_prog or "python",
    {
      stdio = {stdin, stdout, stderr},
      args = {filename},
      cwd = ".",
    }, finish)
else
  handle, err = vim.loop.spawn(vim.g.python3_host_prog or "python3",
    {
      stdio = {stdin, stdout, stderr},
      args = {filename},
      cwd = ".",
    }, finish)
end


@execute_visual_python+=
@write_to_temporary_file
M.execute(fname, ft, true)

@script_variables+=
local global_handle

@set_global_handle+=
global_handle = handle

@kill_global_handle+=
if global_handle then
  global_handle:kill()
  global_handle = nil
end
