##../dash
@spawn_ruby_instance+=
handle, err = vim.loop.spawn("cmd",
	{
		stdio = {stdin, stdout, stderr},
		args = {"/c ruby " .. filename},
		cwd = ".",
	}, finish)

@execute_visual_ruby+=
@write_to_temporary_file
M.execute(fname, ft, true)
