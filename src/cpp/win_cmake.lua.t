##../dash
@execute_cmake_win+=
@find_parent_cmakelists
if cmakelists_path then
	@find_tasks_json_cpp_cmake
	@create_command_line_window
	@read_vs_environment_variables
	@invoke_cmake_windows
end

@find_parent_cmakelists+=
local path = vim.fn.expand("%:p")
local cmakelists_path
while true do
	local parent = vim.fn.fnamemodify(path, ":h")
	@list_files_in_parent
	@if_cmakelists_break

	if parent == path then
		break
	end
	path = parent 
end

@list_files_in_parent+=
local files = {}
for file in vim.gsplit(vim.fn.glob(parent .. "/*"), "\n") do
  if vim.fn.isdirectory(file) == 0 then
    table.insert(files, file)
  end
end

@if_cmakelists_break+=
for _, file in ipairs(files) do
	if vim.fn.fnamemodify(file, ":t") == "CMakeLists.txt" then
		cmakelists_path = file
		break
	end
end

if cmakelists_path then
	break
end

@find_tasks_json_cpp_cmake+=
local build_path = vim.fn.fnamemodify(cmakelists_path, ":h") .. "/build"
local compile_args = { "--build",  build_path }

local json_path = vim.fn.fnamemodify(build_path, ":h") .. "/tasks.json"

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

  @modify_task_config_cpp_cmake
  f.close()
end

@modify_task_config_cpp_cmake+=
if decoded.config then
	table.insert(compile_args, "--config")
  table.insert(compile_args, decoded.config)
end

@read_vs_environment_variables+=
local env = {}
for line in io.lines(vim.g.vsvarlist) do
	table.insert(env, line)
end

assert(vim.tbl_count(env) > 0)

@invoke_cmake_windows+=
handle, err = vim.loop.spawn("cmake",
	{
		stdio = {stdin, stdout, stderr},
    args = compile_args,
		cwd = ".",
		env = env,
	}, function(code, signal)
    vim.schedule(function()
			finish(code, signal)
    end)
end)

