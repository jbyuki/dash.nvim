##../little-runner
@spawn_neovim_process_for_vimscript+=
handle, err = vim.loop.spawn("nvim",
	{
		stdio = {stdin, stdout, stderr},
		args = {"--headless", "-u", "NONE", "-c", "source " .. filename, "-c", "exit"},
		cwd = ".",
	}, function(code, signal)
		vim.schedule(function()
      @if_no_output_clear_console
      @compare_with_previous_output
      @higlight_differences
      @save_current_output
		end)
	end)
