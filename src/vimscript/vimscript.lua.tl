##../little-runner
@spawn_neovim_process_for_vimscript+=
handle, err = vim.loop.spawn("nvim",
	{
		stdio = {stdin, stdout, stderr},
		args = {"--headless", "-u", "NONE", "-c", "source " .. filename, "-c", "exit"},
		cwd = ".",
	}, finish)
