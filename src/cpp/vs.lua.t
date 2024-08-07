##../dash
@implement+=
function M.find_sln()
  local path = vim.fn.expand("%:p")
  local sln_path
  while true do
    local parent = vim.fn.fnamemodify(path, ":h")
    @list_directories_in_parent
    @find_build_directory_with_sln
    @find_sln_in_build_directory

    if sln_path then
      break
    end

    if parent == path then
      break
    end
    path = parent 
  end
  return sln_path
end

@list_directories_in_parent+=
local dirs = {}
for file in vim.gsplit(vim.fn.glob(parent .. "/*"), "\n") do
  if vim.fn.isdirectory(file) == 1 then
    table.insert(dirs, file)
  end
end

@find_build_directory_with_sln+=
local build_path
for _, dir in ipairs(dirs) do
  if vim.fn.fnamemodify(dir, ":t") == "build" then
    build_path = dir
    break
  end
end

@find_sln_in_build_directory+=
if build_path then
  for file in vim.gsplit(vim.fn.glob(build_path .. "/*"), "\n") do
    if vim.fn.isdirectory(file) == 0 then
      if vim.fn.fnamemodify(file, ":e") == "sln" then
        sln_path = file
        break
      end
    end
  end
end

@try_find_vs_solution+=
local vs = M.find_sln()
local build_path = vim.fn.fnamemodify(vs, ":h")

@spawn_vs_compilation+=
@find_tasks_json_cpp_vs
handle, err = vim.loop.spawn("MSBuild.exe",
	{
		stdio = {stdin, stdout, stderr},
    args = compile_args,
		cwd = ".",
	}, function(code, signal)
    vim.schedule(function()
      if code == 0 then
        execute_program()
      else
        @parse_errors_cpp
        @put_errors_in_quickfix_cpp
        finish(code, signal)
      end
    end)
end)

@execute_cpp_program_on_success+=
function execute_program()
  local bin_path = vim.fn.fnamemodify(build_path, ":h") .. "/build"
  local exes = vim.split(vim.fn.glob(bin_path .. "/**/*.exe"), "\n")

	MAX_LINES = 100000000
	@remove_exes

  local execute_program_single
  
  execute_program_single = function(exe_file)
		if not exe_file then
			return
		end
    @find_launch_json_vs_cpp

    @clear_output_lines
    @clear_output_window
    @create_pipes
    handle, err = vim.loop.spawn(exe_file,
      {
        stdio = {stdin, stdout, stderr},
        args = args,
        cwd = ".",
      }, finish)

    @if_spawn_error_print
    @register_pipe_callback_neovim
  end

  assert(#exes >= 0, "Not exe found")

  if #exes > 1 then
    vim.ui.select(exes, {}, execute_program_single)
  else
    execute_program_single(exes[1])
  end
end

@find_launch_json_vs_cpp+=
local args = nil 
local json_path = vim.fn.fnamemodify(build_path, ":h") .. "/launch.json"

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

  @modify_launch_config_cpp_vs
  f.close()
end

@modify_launch_config_cpp_vs+=
args = decoded.args

@find_tasks_json_cpp_vs+=
local compile_args = { vs }

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

  @modify_task_config_cpp_vs
  f.close()
end

@modify_task_config_cpp_vs+=
if decoded.config then
  table.insert(compile_args, ("-p:Configuration=%s"):format(decoded.config))
end

@remove_exes+=
exes = vim.tbl_filter(function(path)
	local filename = vim.fn.fnamemodify(path, ":t")
	if filename == "CompilerIdC.exe" then
		return false
	elseif filename == "CompilerIdCXX.exe" then
		return false
	elseif filename == "CMakeCCompilerId.exe" then
		return false
	elseif filename == "CMakeCXXCompilerId.exe" then
		return false
	end
	return true
end, exes)
