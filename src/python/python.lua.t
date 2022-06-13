##../dash
@spawn_python_instance+=
if vim.fn.has('win32') == 1 then
  @find_launch_json
  handle, err = vim.loop.spawn(vim.g.python3_host_prog or "python",
    {
      stdio = {stdin, stdout, stderr},
      args = args,
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

@find_launch_json+=
local json_path = vim.fn.fnamemodify(filename, ":h") .. "/launch.json"
local args = { filename }
local f = io.open(json_path, "r")
if f then
  local lines = {}
  while true do
    local line = f:read()
    if not line then
      break
    end
    table.insert(lines, line)
  end

  local content = table.concat(lines, "\n")
  local decoded = vim.json.decode(content)

  if decoded.args then
    for _, arg in ipairs(decoded.args) do
      table.insert(args, arg)
    end
  end
  f.close()
end
