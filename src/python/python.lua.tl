##../little-runner
@spawn_python_instance+=
local handle, err = vim.loop.spawn("python",
	{
		stdio = {stdin, stdout, stderr},
		args = {filename},
		cwd = ".",
	}, function(code, signal)
		vim.schedule(function()
      @if_no_output_clear_console
      @compare_with_previous_output
      @higlight_differences
      @save_current_output
		end)
	end)
