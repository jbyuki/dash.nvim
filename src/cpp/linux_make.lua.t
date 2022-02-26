##../dash
@execute_make_build+=
local execute_program_linux
@execute_make
@execute_linux_if_exists

@execute_make+=
handle, err = vim.loop.spawn("make",
	{
		stdio = {stdin, stdout, stderr},
		args = { "all" },
		cwd = ".",
	}, function(code, signal)
    vim.schedule(function()
      @find_target_name_in_makefile
      if code == 0 and exe_file and exe_file ~= "" then
        execute_program_linux(exe_file)
      else
        finish(code, signal)
      end
    end)
  end)

@find_target_name_in_makefile+=
local makefile = vim.fn.glob("Makefile")
local exe_file
for line in io.lines(makefile) do
  exe_file = line:match("^all:%s*(%w+)")
  if exe_file then
    break
  end
end

@execute_linux_if_exists+=
function execute_program_linux(exe_file)
  @clear_output_lines
  @clear_output_window
  @create_pipes
  handle, err = vim.loop.spawn("./" .. exe_file,
    {
      stdio = {stdin, stdout, stderr},
      cwd = ".",
    }, finish)

  @if_spawn_error_print
  @register_pipe_callback_neovim
end
